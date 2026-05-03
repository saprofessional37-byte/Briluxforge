// lib/features/updater/domain/updater_service.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.3

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:briluxforge/core/database/app_database.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/delegation/data/engine/default_model_reconciler.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/updater/data/models/binary_update_info.dart';
import 'package:briluxforge/features/updater/data/models/brain_update_info.dart';
import 'package:briluxforge/features/updater/data/models/feature_flags_model.dart';
import 'package:briluxforge/features/updater/data/models/kill_switches_model.dart';
import 'package:briluxforge/features/updater/data/models/update_artifact.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/data/repositories/binary_download_repository.dart';
import 'package:briluxforge/features/updater/data/repositories/brain_repository.dart';
import 'package:briluxforge/features/updater/data/repositories/manifest_repository.dart';
import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';
import 'package:briluxforge/features/updater/data/update_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/updater/domain/platform_installer.dart';
import 'package:briluxforge/features/updater/domain/version_comparator.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that orchestrates the complete OTA update lifecycle.
///
/// Consumers access it through [updaterProvider] — never instantiate directly.
///
/// ## Lifecycle
/// 1. [bootstrap] — called once from `main.dart` after Firebase init.
/// 2. A periodic 6-hour check timer starts; an immediate check fires 3 s
///    after bootstrap.
/// 3. On each check: fetch + verify manifest → apply brain/flags/switches →
///    optionally start binary download → transition state machine.
///
/// ## Thread safety
/// All state mutations run on the Dart event loop. The download mutex
/// ([_downloadActive]) prevents concurrent downloads.
class UpdaterService {
  UpdaterService._();

  static final UpdaterService instance = UpdaterService._();

  // ── Dependencies (injectable for testing) ──────────────────────────────────
  ManifestRepository _manifestRepo = ManifestRepository();
  BinaryDownloadRepository _binaryRepo = BinaryDownloadRepository();
  BrainRepository _brainRepo = BrainRepository();

  // ── State streams ──────────────────────────────────────────────────────────
  final _stateController = StreamController<UpdateState>.broadcast();
  final _brainVersionController = StreamController<int>.broadcast();
  final _featureFlagsController =
      StreamController<FeatureFlagsModel>.broadcast();
  final _killSwitchesController =
      StreamController<KillSwitchesModel>.broadcast();

  // ── Internal state ─────────────────────────────────────────────────────────
  UpdateState _currentState =
      const UpdateIdle(installedVersion: '0.0.0');
  String _installedVersion = '0.0.0';
  int _installedBrainVersion = 0;
  int _consecutiveFailures = 0;
  bool _downloadActive = false;
  Timer? _checkTimer;

  // Prevent re-entrant check runs.
  bool _checkRunning = false;

  // ── Public streams ─────────────────────────────────────────────────────────

  Stream<UpdateState> get stateStream => _stateController.stream;
  Stream<int> get brainVersionStream => _brainVersionController.stream;
  Stream<FeatureFlagsModel> get featureFlagsStream =>
      _featureFlagsController.stream;
  Stream<KillSwitchesModel> get killSwitchesStream =>
      _killSwitchesController.stream;
  UpdateState get currentState => _currentState;
  int get consecutiveFailures => _consecutiveFailures;

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  /// Called once from `main.dart` immediately after `Firebase.initializeApp()`.
  ///
  /// Order of operations (§6.3):
  ///   1. Read installed version + brain version.
  ///   2. Scan `pending/` for a staged update; cross-check against the Drift
  ///      `PendingUpdates` table. Wipe on any inconsistency.
  ///   3. Start periodic check timer.
  ///   4. Kick off a non-blocking first check after a 3-second delay.
  Future<void> bootstrap({
    ManifestRepository? manifestRepo,
    BinaryDownloadRepository? binaryRepo,
    BrainRepository? brainRepo,
  }) async {
    if (manifestRepo != null) _manifestRepo = manifestRepo;
    if (binaryRepo != null) _binaryRepo = binaryRepo;
    if (brainRepo != null) _brainRepo = brainRepo;

    // 1. Read installed version.
    final packageInfo = await PackageInfo.fromPlatform();
    _installedVersion = packageInfo.version;

    // 2. Read installed brain version.
    final prefs = await SharedPreferences.getInstance();
    _installedBrainVersion = prefs.getInt('brain_version_installed') ?? 0;

    // Emit initial idle state.
    _setState(UpdateIdle(
      installedVersion: _installedVersion,
    ));

    // 3. Reconcile pending update (cross-check disk + Drift table).
    await _reconcilePendingUpdate(prefs);

    // 4. Start periodic check timer.
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(kUpdateCheckInterval, (_) => _runCheck());

    // 5. Trigger immediate first check (non-blocking, 3 s delay per §8.1).
    Future<void>.delayed(const Duration(seconds: 3), _runCheck);
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  /// Triggers a manifest check immediately, regardless of the timer.
  Future<void> checkNow() async {
    if (_checkRunning) return;
    await _runCheck();
  }

  /// Transitions [UpdateReady] → [UpdateInstalling] and hands off to the
  /// platform installer.
  ///
  /// The platform installer script exits the process — this method does not
  /// return under normal operation.
  Future<void> startInstall() async {
    final state = _currentState;
    if (state is! UpdateReady) return;

    _setState(UpdateInstalling(targetVersion: state.targetVersion));

    try {
      final dirs = await _updateDirs();
      final pendingDir = dirs.$1;

      // Locate the staged payload file.
      final payloadFile = await _findPendingPayload(pendingDir);
      if (payloadFile == null) {
        throw const StagingException(
          message: 'The staged update file could not be found.',
          technicalDetail: 'No payload file in pending directory.',
        );
      }

      // Re-verify integrity before handing to the installer (§10.1.5).
      await _reVerifyPayload(payloadFile, pendingDir);

      // Resolve install directory from the running executable.
      final installDir = File(Platform.resolvedExecutable).parent;

      final installer = PlatformInstaller.forCurrentPlatform();
      await installer.prepareAndLaunch(
        stagedPayload: payloadFile,
        installDir: installDir,
        pendingDir: pendingDir,
        runningPid: pid,
      );
      // Process exits inside prepareAndLaunch — execution never reaches here.
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Install initiation failed.', e, st);
      _setState(UpdateFailed(
        userMessage:
            'Something went wrong preparing the update. Please try again.',
        technicalDetail: e.toString(),
      ));
    }
  }

  /// Deletes the staged artifact and returns to [UpdateIdle].
  Future<void> cancelStagedUpdate() async {
    try {
      final dirs = await _updateDirs();
      await _wipePendingDir(dirs.$1);
      await _clearDriftRow();
    } catch (e) {
      AppLogger.w('[Updater]', 'Error clearing staged update: $e');
    }
    _setState(UpdateIdle(
      installedVersion: _installedVersion,
      lastCheckAt: DateTime.now(),
    ));
  }

  /// Called by [UpdateGate] when [UpdateForced] is entered — starts the
  /// download without waiting for user interaction (§6.3).
  Future<void> forceDownload() async {
    if (_currentState is! UpdateForced) return;
    // Re-trigger a check which will detect forced state and start download.
    unawaited(_runCheck());
  }

  // ── Core check cycle ───────────────────────────────────────────────────────

  Future<void> _runCheck() async {
    if (_checkRunning) return;
    if (_currentState is UpdateDownloading ||
        _currentState is UpdateInstalling) {
      return;
    }

    _checkRunning = true;
    _setState(const UpdateChecking());

    try {
      final manifest = await _manifestRepo.fetchAndVerify();

      // Apply feature flags and kill switches (every check, regardless of
      // binary or brain version changes — §7.4).
      _featureFlagsController.add(manifest.featureFlags);
      _killSwitchesController.add(manifest.killSwitches);

      // Brain hot-sync (§7.1).
      if (manifest.brain != null) {
        unawaited(_handleBrainSync(manifest.brain!));
      }

      // Binary update logic.
      final binaryInfo = manifest.binary;
      if (binaryInfo == null) {
        _consecutiveFailures = 0;
        _setState(UpdateIdle(
          installedVersion: _installedVersion,
          lastCheckAt: DateTime.now(),
        ));
        return;
      }

      // KILL-SWITCH-OBEY LAW / MONOTONIC-VERSION LAW (§1.2).
      final isBlocklisted =
          binaryInfo.blocklist.contains(_installedVersion);
      final isBelowMinimum = VersionComparator.isLessThan(
        _installedVersion,
        binaryInfo.minimumVersion,
      );

      if (isBlocklisted || isBelowMinimum) {
        AppLogger.w(
          '[Updater]',
          'Installed v$_installedVersion is ${isBlocklisted ? 'in blocklist' : 'below minimum ${binaryInfo.minimumVersion}'}. '
          'Entering Forced Update Mode.',
        );
        _consecutiveFailures = 0;
        _setState(UpdateForced(
          targetVersion: binaryInfo.version,
          reason: isBlocklisted ? 'blocklist' : 'minimum_version',
          releaseNotesMarkdown: binaryInfo.releaseNotesMarkdown,
        ));
        // Auto-start download for forced updates.
        unawaited(_startBinaryDownload(binaryInfo));
        return;
      }

      // Already up to date — MONOTONIC-VERSION LAW.
      if (!VersionComparator.isGreaterThan(
        binaryInfo.version,
        _installedVersion,
      )) {
        AppLogger.d(
          '[Updater]',
          'Manifest binary v${binaryInfo.version} is not newer than '
          'installed v$_installedVersion. No binary update.',
        );
        _consecutiveFailures = 0;
        _setState(UpdateIdle(
          installedVersion: _installedVersion,
          lastCheckAt: DateTime.now(),
        ));
        return;
      }

      // Find a matching artifact for the current platform + arch.
      final artifact = _findMatchingArtifact(binaryInfo.artifacts);
      if (artifact == null) {
        AppLogger.w(
          '[Updater]',
          'No artifact matches current platform '
          '(${_currentPlatform()}/${_currentArch()}). '
          'Brain/flags still applied.',
        );
        _consecutiveFailures = 0;
        _setState(UpdateIdle(
          installedVersion: _installedVersion,
          lastCheckAt: DateTime.now(),
        ));
        return;
      }

      // Kick off the download (non-blocking from this check cycle's POV).
      _consecutiveFailures = 0;
      unawaited(_startBinaryDownload(binaryInfo, artifact: artifact));
    } catch (e) {
      _consecutiveFailures++;
      AppLogger.w(
        '[Updater]',
        'Check cycle failed (consecutive: $_consecutiveFailures): $e',
      );
      _setState(UpdateFailed(
        userMessage: _userMessageForError(e),
        technicalDetail: e.toString(),
      ));

      // Transition back to idle after a short delay so the next tick starts
      // fresh (§6.2: UpdateFailed → UpdateIdle on next scheduled tick).
      Future<void>.delayed(const Duration(seconds: 10), () {
        if (_currentState is UpdateFailed) {
          _setState(UpdateIdle(
            installedVersion: _installedVersion,
          ));
        }
      });
    } finally {
      _checkRunning = false;
    }
  }

  // ── Binary download ────────────────────────────────────────────────────────

  Future<void> _startBinaryDownload(
    BinaryUpdateInfo binaryInfo, {
    UpdateArtifact? artifact,
  }) async {
    if (_downloadActive) return;
    _downloadActive = true;

    final resolvedArtifact =
        artifact ?? _findMatchingArtifact(binaryInfo.artifacts);
    if (resolvedArtifact == null) {
      _downloadActive = false;
      return;
    }

    final dirs = await _updateDirs();
    final pendingDir = dirs.$1;
    final stagingDir = dirs.$2;

    try {
      await for (final progress in _binaryRepo.download(
        artifact: resolvedArtifact,
        stagingDir: stagingDir,
        pendingDir: pendingDir,
        targetVersion: binaryInfo.version,
      )) {
        if (progress.isComplete) {
          // Verified + staged — transition to Verifying momentarily, then Ready.
          _setState(UpdateVerifying(targetVersion: binaryInfo.version));
          await _persistStagedUpdate(
            binaryInfo.version,
            pendingDir,
            resolvedArtifact.sha256,
          );
          _setState(UpdateReady(
            targetVersion: binaryInfo.version,
            releaseNotesMarkdown: binaryInfo.releaseNotesMarkdown,
            stagedAt: DateTime.now().toUtc(),
          ));
          AppLogger.i(
            '[Updater]',
            'Binary v${binaryInfo.version} staged and ready.',
          );
        } else {
          _setState(UpdateDownloading(
            targetVersion: binaryInfo.version,
            bytesReceived: progress.bytesReceived,
            bytesTotal: progress.bytesTotal,
          ));
        }
      }
    } on ArtifactVerificationException catch (e) {
      AppLogger.e('[Updater]', 'Artifact verification failed. Payload deleted.', e);
      _setState(UpdateFailed(
        userMessage: e.message,
        technicalDetail: e.technicalDetail ?? e.toString(),
      ));
    } on StagingException catch (e) {
      AppLogger.e('[Updater]', 'Staging failed.', e);
      _setState(UpdateFailed(
        userMessage: e.message,
        technicalDetail: e.technicalDetail ?? e.toString(),
      ));
    } catch (e) {
      AppLogger.e('[Updater]', 'Download failed.', e);
      _setState(UpdateFailed(
        userMessage: _userMessageForError(e),
        technicalDetail: e.toString(),
      ));
    } finally {
      _downloadActive = false;
    }
  }

  // ── Brain hot-sync (§7.1) ──────────────────────────────────────────────────

  Future<void> _handleBrainSync(BrainUpdateInfo brainInfo) async {
    if (brainInfo.version <= _installedBrainVersion) {
      AppLogger.d(
        '[Brain]',
        'Brain v${brainInfo.version} is not newer than installed '
        'v$_installedBrainVersion. No sync.',
      );
      return;
    }

    final appSupport = await getApplicationSupportDirectory();
    final targetFile = File(
      p.join(appSupport.path, 'Briluxforge', 'brain', 'current.json'),
    );

    try {
      final newVersion = await _brainRepo.fetchAndApply(
        brainInfo: brainInfo,
        targetFile: targetFile,
      );

      final oldVersion = _installedBrainVersion;
      _installedBrainVersion = newVersion;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('brain_version_installed', newVersion);

      // Notify Riverpod providers watching brain version.
      _brainVersionController.add(newVersion);

      AppLogger.i(
        '[Brain]',
        'hot-sync: v$oldVersion → v$newVersion',
      );

      // Re-run the DefaultModelReconciler (§7.1 step 5).
      // We run it silently here; the UI layer picks up changes via
      // liveModelProfilesProvider rebuilding on brain version change.
      await _runReconcilerAfterBrainSync(targetFile, prefs);
    } catch (e) {
      // Brain sync failure is not fatal (§7.3) — UpdateState is unchanged.
      AppLogger.e('[Brain]', 'Brain sync failed; continuing with stale brain.', e);
    }
  }

  /// Runs [DefaultModelReconciler] against the freshly-written brain JSON and
  /// persists any change to SharedPreferences (§7.1 step 5).
  Future<void> _runReconcilerAfterBrainSync(
    File brainFile,
    SharedPreferences prefs,
  ) async {
    try {
      final rawJson =
          jsonDecode(brainFile.readAsStringSync()) as Map<String, Object?>;
      final allModels = (rawJson['models'] as List<dynamic>)
          .map((e) => ModelProfile.fromJson(e as Map<String, Object?>))
          .toList();
      final routeableModels =
          allModels.where((m) => !m.isBenchmark).toList();

      final currentDefaultId = prefs.getString('default_model_id');
      // Connected providers are not accessible here (no Riverpod ref).
      // Pass empty list — reconciler will still find a safe fallback.
      const reconciler = DefaultModelReconciler();
      final result = reconciler.reconcile(
        currentDefaultId: currentDefaultId,
        availableModels: routeableModels,
        connectedProviders: const [],
      );

      if (result.changed) {
        await prefs.setString('default_model_id', result.newModelId);
        AppLogger.i(
          '[Brain]',
          'DefaultModelReconciler changed default from '
          '"$currentDefaultId" → "${result.newModelId}".',
        );
      }
    } catch (e) {
      AppLogger.w('[Brain]', 'DefaultModelReconciler post-brain-sync run failed: $e');
    }
  }

  // ── Pending-update reconciliation (§6.5) ───────────────────────────────────

  Future<void> _reconcilePendingUpdate(SharedPreferences prefs) async {
    final dirs = await _updateDirs();
    final pendingDir = dirs.$1;

    final metadataFile = File(p.join(pendingDir.path, 'metadata.json'));

    if (!metadataFile.existsSync()) {
      // No pending update on disk.
      await _clearDriftRow();
      return;
    }

    try {
      final metaJson =
          jsonDecode(metadataFile.readAsStringSync()) as Map<String, Object?>;
      final version = metaJson['version'] as String?;
      final stagedAtRaw = metaJson['staged_at'] as String?;
      final sha256Hex = metaJson['sha256'] as String?;

      if (version == null || stagedAtRaw == null || sha256Hex == null) {
        AppLogger.w(
          '[Updater]',
          'Pending metadata is malformed. Wiping pending dir.',
        );
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
        return;
      }

      final stagedAt = DateTime.tryParse(stagedAtRaw);
      if (stagedAt == null) {
        AppLogger.w('[Updater]', 'Staged-at timestamp unparseable. Wiping.');
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
        return;
      }

      // Expiry check (§6.5 kStagedUpdateMaxAge).
      if (DateTime.now().toUtc().difference(stagedAt) > kStagedUpdateMaxAge) {
        AppLogger.i(
          '[Updater]',
          'Staged update v$version has expired. Wiping.',
        );
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
        return;
      }

      // Find payload file.
      final payloadFile = await _findPendingPayload(pendingDir);
      if (payloadFile == null) {
        AppLogger.w(
          '[Updater]',
          'Pending metadata exists but payload file missing. Wiping.',
        );
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
        return;
      }

      // SHA-256 cross-check (§6.5 — every bootstrap re-verifies).
      final fileBytes = await payloadFile.readAsBytes();
      final actualHash = sha256.convert(fileBytes).toString();
      if (actualHash != sha256Hex) {
        AppLogger.e(
          '[Updater]',
          'Bootstrap SHA-256 mismatch for staged update v$version. '
          'Treating as tampered. Wiping.',
        );
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
        return;
      }

      // Ed25519 re-verify (§10.1.5).
      final sigFile = File(p.join(pendingDir.path, 'payload.sig'));
      if (sigFile.existsSync()) {
        try {
          final sigBytes = base64.decode(sigFile.readAsStringSync().trim());
          final valid = await Ed25519Verifier.verify(
            message: fileBytes,
            signature: sigBytes,
          );
          if (!valid) {
            AppLogger.e(
              '[Updater]',
              'Bootstrap Ed25519 verification FAILED for staged v$version. '
              'SIGNED-OR-DIE LAW. Wiping.',
            );
            await _wipePendingDir(pendingDir);
            await _clearDriftRow();
            return;
          }
        } catch (e) {
          AppLogger.e('[Updater]', 'Signature re-verify error on bootstrap.', e);
          await _wipePendingDir(pendingDir);
          await _clearDriftRow();
          return;
        }
      }

      // Sync Drift table with on-disk metadata.
      await _upsertDriftRow(
        version: version,
        stagedAt: stagedAt,
        sha256: sha256Hex,
        payloadPath: payloadFile.path,
      );

      // The staged update is valid — emit UpdateReady.
      AppLogger.i(
        '[Updater]',
        'Found valid staged update v$version from bootstrap. Emitting UpdateReady.',
      );

      // We need release notes — they won't be in metadata.json. Emit empty
      // release notes here; if the manifest check completes it will update.
      _setState(UpdateReady(
        targetVersion: version,
        releaseNotesMarkdown: '',
        stagedAt: stagedAt,
      ));
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Error reconciling pending update. Wiping.', e, st);
      try {
        await _wipePendingDir(pendingDir);
        await _clearDriftRow();
      } catch (_) {}
      // Fall through to idle — set in bootstrap after this call.
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(UpdateState state) {
    _currentState = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  Future<(Directory, Directory)> _updateDirs() async {
    final appSupport = await getApplicationSupportDirectory();
    final base = p.join(appSupport.path, 'Briluxforge', 'updates');
    final pendingDir = Directory(p.join(base, 'pending'));
    final stagingDir = Directory(p.join(base, 'staging'));
    await pendingDir.create(recursive: true);
    await stagingDir.create(recursive: true);
    return (pendingDir, stagingDir);
  }

  Future<File?> _findPendingPayload(Directory pendingDir) async {
    if (!pendingDir.existsSync()) return null;
    try {
      final entities = pendingDir.listSync().whereType<File>().toList();
      for (final file in entities) {
        final name = p.basename(file.path);
        if (name.startsWith('payload') &&
            name != 'payload.sig' &&
            !name.endsWith('.json')) {
          return file;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _reVerifyPayload(File payloadFile, Directory pendingDir) async {
    final bytes = await payloadFile.readAsBytes();
    final metadataFile = File(p.join(pendingDir.path, 'metadata.json'));
    final metaJson =
        jsonDecode(metadataFile.readAsStringSync()) as Map<String, Object?>;
    final expectedHash = metaJson['sha256'] as String?;
    if (expectedHash != null) {
      final actualHash = sha256.convert(bytes).toString();
      if (actualHash != expectedHash) {
        await payloadFile.delete();
        throw const ArtifactVerificationException(
          message:
              'The staged update failed integrity verification. It has been removed.',
          technicalDetail:
              'SHA-256 mismatch during pre-install re-verification.',
        );
      }
    }

    final sigFile = File(p.join(pendingDir.path, 'payload.sig'));
    if (sigFile.existsSync()) {
      final sigBytes = base64.decode(sigFile.readAsStringSync().trim());
      final valid = await Ed25519Verifier.verify(
        message: bytes,
        signature: sigBytes,
      );
      if (!valid) {
        await payloadFile.delete();
        await sigFile.delete();
        throw const ArtifactVerificationException(
          message:
              'The staged update failed security verification. It has been removed.',
          technicalDetail:
              'Ed25519 verification failed during pre-install re-verification.',
        );
      }
    }
  }

  Future<void> _wipePendingDir(Directory pendingDir) async {
    if (!pendingDir.existsSync()) return;
    try {
      for (final entity in pendingDir.listSync()) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.w('[Updater]', 'Error wiping pending dir: $e');
    }
  }

  Future<void> _persistStagedUpdate(
    String version,
    Directory pendingDir,
    String sha256Hex,
  ) async {
    final payloadFile = await _findPendingPayload(pendingDir);
    if (payloadFile == null) return;
    final now = DateTime.now().toUtc();
    await _upsertDriftRow(
      version: version,
      stagedAt: now,
      sha256: sha256Hex,
      payloadPath: payloadFile.path,
    );
  }

  Future<void> _upsertDriftRow({
    required String version,
    required DateTime stagedAt,
    required String sha256,
    required String payloadPath,
  }) async {
    try {
      final db = AppDatabase();
      await db
          .into(db.pendingUpdates)
          .insertOnConflictUpdate(PendingUpdatesCompanion.insert(
            version: version,
            stagedAt: stagedAt,
            sha256: sha256,
            payloadPath: payloadPath,
          ));
      await db.close();
    } catch (e) {
      AppLogger.w('[Updater]', 'Failed to upsert PendingUpdates row: $e');
    }
  }

  Future<void> _clearDriftRow() async {
    try {
      final db = AppDatabase();
      await db.delete(db.pendingUpdates).go();
      await db.close();
    } catch (e) {
      AppLogger.w('[Updater]', 'Failed to clear PendingUpdates table: $e');
    }
  }

  UpdateArtifact? _findMatchingArtifact(List<UpdateArtifact> artifacts) {
    final platform = _currentPlatform();
    final arch = _currentArch();
    try {
      return artifacts.firstWhere(
        (a) => a.platform == platform && a.arch == arch,
      );
    } catch (_) {
      return null;
    }
  }

  String _currentPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _currentArch() {
    final abi = Abi.current();
    if (abi == Abi.macosArm64) return 'arm64';
    return 'x64';
  }

  String _userMessageForError(Object e) {
    if (e is ManifestFetchException) return e.message;
    if (e is ManifestSignatureException) return e.message;
    if (e is ManifestSchemaException) return e.message;
    if (e is ArtifactDownloadException) return e.message;
    if (e is ArtifactVerificationException) return e.message;
    if (e is StagingException) return e.message;
    return 'An unexpected error occurred while checking for updates.';
  }
}

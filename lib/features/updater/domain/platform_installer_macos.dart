// lib/features/updater/domain/platform_installer_macos.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §9.2

import 'dart:io';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/updater/domain/platform_installer.dart';
import 'package:path/path.dart' as p;

/// macOS install-on-restart strategy (§9.2).
///
/// Packaging format: ZIP containing `Briluxforge.app` bundle.
///
/// The install path is resolved from [Platform.resolvedExecutable] — the
/// installer never hardcodes `/Applications` (§9.2 requirement).
///
/// Gatekeeper / notarization is a CI/CD concern (§9.2); this class only
/// generates the shell mechanics.
class MacOSPlatformInstaller extends PlatformInstaller {
  const MacOSPlatformInstaller();

  @override
  Future<String> generateScript({
    required File stagedPayload,
    required Directory installDir,
    required int runningPid,
  }) async {
    // installDir is the .app bundle directory (e.g. /Applications/Briluxforge.app).
    final zipPath = stagedPayload.absolute.path;
    final appBundlePath = installDir.absolute.path;

    // Staged extraction lives next to the zip so we can do an atomic `mv`.
    final stagedAppPath = p.join(
      stagedPayload.parent.path,
      'Briluxforge.app',
    );

    return '''#!/bin/bash
set -euo pipefail

ZIP_PATH="$zipPath"
APP_BUNDLE="$appBundlePath"
STAGED_APP="$stagedAppPath"
OLD_PID=$runningPid

# Wait for the old process to exit.
while kill -0 "\$OLD_PID" 2>/dev/null; do
  sleep 0.2
done

# Extract the staged ZIP.
ditto -x -k --sequesterRsrc --rsrc "\$ZIP_PATH" "\$(dirname "\$STAGED_APP")"

# Atomic replace.
rm -rf "\$APP_BUNDLE"
mv "\$STAGED_APP" "\$APP_BUNDLE"

# Clean up zip.
rm -f "\$ZIP_PATH"

# Relaunch.
open "\$APP_BUNDLE"
''';
  }

  @override
  Future<void> prepareAndLaunch({
    required File stagedPayload,
    required Directory installDir,
    required Directory pendingDir,
    required int runningPid,
  }) async {
    // Check writability of the install location (§9.2 admin-check).
    final parentDir = installDir.parent;
    final canWrite = await _isWritable(parentDir);
    if (!canWrite) {
      AppLogger.e(
        '[Installer]',
        'Install directory "${parentDir.path}" is not writable. '
        'Admin privileges required.',
      );
      throw PlatformInstallerException(
        message:
            'This update needs to be installed by an administrator. '
            'Please reinstall from the website or run with elevated privileges.',
        technicalDetail:
            'Directory "${parentDir.path}" is not writable by the current user.',
      );
    }

    final scriptContent = await generateScript(
      stagedPayload: stagedPayload,
      installDir: installDir,
      runningPid: runningPid,
    );

    final scriptFile = File(p.join(pendingDir.path, 'installer.sh'));
    try {
      await scriptFile.writeAsString(scriptContent, flush: true);
      await Process.run('chmod', ['+x', scriptFile.path]);
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Failed to write macOS installer script.', e, st);
      throw PlatformInstallerException(
        message: 'Could not prepare the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    AppLogger.i('[Installer]', 'Launching macOS installer script; exiting app.');
    try {
      await Process.start(
        '/bin/bash',
        [scriptFile.path],
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Failed to launch macOS installer.', e, st);
      throw PlatformInstallerException(
        message: 'Could not start the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    exit(0);
  }

  Future<bool> _isWritable(Directory dir) async {
    try {
      final testFile = File(p.join(dir.path, '.briluxforge_write_test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

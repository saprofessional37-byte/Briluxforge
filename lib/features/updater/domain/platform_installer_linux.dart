// lib/features/updater/domain/platform_installer_linux.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §9.3

import 'dart:io';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/updater/domain/platform_installer.dart';
import 'package:path/path.dart' as p;

/// Linux AppImage install-on-restart strategy (§9.3).
///
/// The staged AppImage replaces the currently-running AppImage in-place.
/// [Platform.resolvedExecutable] is the source of truth for the install path
/// (the user chooses where their AppImage lives).
class LinuxPlatformInstaller extends PlatformInstaller {
  const LinuxPlatformInstaller();

  @override
  Future<String> generateScript({
    required File stagedPayload,
    required Directory installDir,
    required int runningPid,
  }) async {
    final newAppImagePath = stagedPayload.absolute.path;
    // The old AppImage path: the currently-running executable.
    final oldAppImagePath = Platform.resolvedExecutable;

    return '''#!/bin/bash
set -euo pipefail

OLD_APPIMAGE_PATH="$oldAppImagePath"
NEW_APPIMAGE_PATH="$newAppImagePath"
OLD_PID=$runningPid

# Wait for the old process to exit.
while kill -0 "\$OLD_PID" 2>/dev/null; do
  sleep 0.2
done

# Atomic replace.
mv "\$NEW_APPIMAGE_PATH" "\$OLD_APPIMAGE_PATH"
chmod +x "\$OLD_APPIMAGE_PATH"

# Relaunch.
exec "\$OLD_APPIMAGE_PATH" &
''';
  }

  @override
  Future<void> prepareAndLaunch({
    required File stagedPayload,
    required Directory installDir,
    required Directory pendingDir,
    required int runningPid,
  }) async {
    // Make the staged AppImage executable before the swap.
    try {
      await Process.run('chmod', ['+x', stagedPayload.path]);
    } catch (e) {
      AppLogger.w('[Installer]', 'chmod +x on staged AppImage failed: $e');
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
      AppLogger.e('[Installer]', 'Failed to write Linux installer script.', e, st);
      throw PlatformInstallerException(
        message: 'Could not prepare the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    AppLogger.i('[Installer]', 'Launching Linux installer script; exiting app.');
    try {
      await Process.start(
        '/bin/bash',
        [
          scriptFile.path,
          Platform.resolvedExecutable,
          stagedPayload.absolute.path,
          '$runningPid',
        ],
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Failed to launch Linux installer.', e, st);
      throw PlatformInstallerException(
        message: 'Could not start the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    exit(0);
  }
}

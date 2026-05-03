// lib/features/updater/domain/platform_installer_windows.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §9.1

import 'dart:io';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/updater/domain/platform_installer.dart';
import 'package:path/path.dart' as p;

/// Windows install-on-restart strategy (§9.1).
///
/// Packaging format: ZIP containing the full Flutter Windows build output
/// (briluxforge.exe + DLLs + data/ + flutter_assets/).
///
/// The generated CMD batch file:
///   1. Polls until the Briluxforge process exits (by PID).
///   2. Extracts the staged ZIP over the install directory.
///   3. Launches briluxforge.exe.
///   4. Deletes itself.
///
/// Paths are double-quoted throughout to handle spaces (§9.1 requirement).
class WindowsPlatformInstaller extends PlatformInstaller {
  const WindowsPlatformInstaller();

  @override
  Future<String> generateScript({
    required File stagedPayload,
    required Directory installDir,
    required int runningPid,
  }) async {
    // Resolve paths with forward slashes normalised to backslashes for CMD.
    final zipPath = stagedPayload.absolute.path;
    final installPath = installDir.absolute.path;
    final exePath = p.join(installPath, 'briluxforge.exe');

    // The script extracts to a temp subfolder then moves files over, so the
    // install directory (and its shortcuts) are never deleted as a whole.
    final extractTmp = p.join(installPath, '_briluxforge_update_tmp');
    final scriptPath = p.join(
      stagedPayload.parent.path,
      'installer.cmd',
    );

    return '''@echo off
setlocal EnableDelayedExpansion

:: Wait for Briluxforge (PID $runningPid) to exit — poll every 200 ms.
:wait_loop
  tasklist /FI "PID eq $runningPid" 2>NUL | find /I "$runningPid" >NUL
  if not errorlevel 1 (
    timeout /T 1 /NOBREAK >NUL 2>&1
    goto wait_loop
  )

:: Extract the update ZIP to a temporary sub-directory.
if exist "$extractTmp" rd /S /Q "$extractTmp"
mkdir "$extractTmp"
powershell -NoProfile -NonInteractive -Command "Expand-Archive -Path '$zipPath' -DestinationPath '$extractTmp' -Force"
if errorlevel 1 goto :fail

:: Copy extracted files over the existing installation.
:: /E = all subdirs, /Y = overwrite without prompt, /I = assume destination is dir.
xcopy /E /Y /I "$extractTmp\\*" "$installPath\\" >NUL
if errorlevel 1 goto :fail

:: Clean up.
rd /S /Q "$extractTmp"
if exist "$zipPath" del /F /Q "$zipPath"

:: Relaunch.
start "" "$exePath"
goto :eof

:fail
echo Briluxforge updater failed. Please reinstall from the website. >&2

:eof
:: Self-delete (the batch file schedules its own deletion on next tick).
(goto) 2>NUL & del /F /Q "$scriptPath"
''';
  }

  @override
  Future<void> prepareAndLaunch({
    required File stagedPayload,
    required Directory installDir,
    required Directory pendingDir,
    required int runningPid,
  }) async {
    final scriptContent = await generateScript(
      stagedPayload: stagedPayload,
      installDir: installDir,
      runningPid: runningPid,
    );

    final scriptFile = File(p.join(pendingDir.path, 'installer.cmd'));
    try {
      await scriptFile.writeAsString(scriptContent, flush: true);
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Failed to write Windows installer script.', e, st);
      throw PlatformInstallerException(
        message: 'Could not prepare the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    AppLogger.i('[Installer]', 'Launching Windows installer script; exiting app.');
    try {
      await Process.start(
        'cmd',
        ['/c', 'start', '/b', scriptFile.path],
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      AppLogger.e('[Installer]', 'Failed to launch Windows installer.', e, st);
      throw PlatformInstallerException(
        message: 'Could not start the update installer.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    // Hand off to the script — the process exits immediately.
    exit(0);
  }
}

// lib/features/updater/domain/platform_installer.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §9

import 'dart:io';

import 'package:briluxforge/features/updater/domain/platform_installer_linux.dart';
import 'package:briluxforge/features/updater/domain/platform_installer_macos.dart';
import 'package:briluxforge/features/updater/domain/platform_installer_windows.dart';

/// Abstract base class for all platform-specific install-on-restart installers.
///
/// The install pattern is: write a detached script → launch it detached →
/// exit the Flutter process immediately. The script then:
///   1. Waits for the running process to exit.
///   2. Replaces the install-directory contents with the staged payload.
///   3. Re-launches the updated binary.
///
/// Concrete subclasses implement the platform-specific logic. [generateScript]
/// returns the script text without executing it, enabling snapshot testing
/// (the "dry-run mode" required by §Phase 11.5).
abstract class PlatformInstaller {
  const PlatformInstaller();

  /// Returns the installer script as a plain [String] without writing or
  /// executing it.
  ///
  /// [stagedPayload] — the verified payload file in the `pending/` directory.
  /// [installDir] — the directory containing the running binary (resolved from
  ///                [Platform.resolvedExecutable] by the caller).
  Future<String> generateScript({
    required File stagedPayload,
    required Directory installDir,
    required int runningPid,
  });

  /// Writes the installer script to disk, makes it executable, launches it
  /// detached, then **exits the current Flutter process**.
  ///
  /// This method does not return under normal operation.
  ///
  /// Throws [PlatformInstallerException] if the script cannot be written or
  /// the launcher process cannot be started.
  Future<void> prepareAndLaunch({
    required File stagedPayload,
    required Directory installDir,
    required Directory pendingDir,
    required int runningPid,
  });

  /// Returns the correct [PlatformInstaller] for the current OS.
  static PlatformInstaller forCurrentPlatform() {
    if (Platform.isWindows) return const WindowsPlatformInstaller();
    if (Platform.isMacOS) return const MacOSPlatformInstaller();
    if (Platform.isLinux) return const LinuxPlatformInstaller();
    throw UnsupportedError(
      'PlatformInstaller: unsupported OS "${Platform.operatingSystem}".',
    );
  }
}

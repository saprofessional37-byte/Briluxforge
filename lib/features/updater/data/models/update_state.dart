// lib/features/updater/data/models/update_state.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.1

import 'package:flutter/foundation.dart';

/// Every possible state of the updater, modeled as a sealed hierarchy.
/// The UI switches exhaustively on this type. Never use strings or enums
/// with ad-hoc payloads — the compiler must prove completeness.
@immutable
sealed class UpdateState {
  const UpdateState();
}

final class UpdateIdle extends UpdateState {
  const UpdateIdle({required this.installedVersion, this.lastCheckAt});

  final String installedVersion;
  final DateTime? lastCheckAt;
}

final class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

final class UpdateDownloading extends UpdateState {
  const UpdateDownloading({
    required this.targetVersion,
    required this.bytesReceived,
    required this.bytesTotal,
  });

  final String targetVersion;
  final int bytesReceived;
  final int bytesTotal;

  double get progress => bytesTotal == 0 ? 0.0 : bytesReceived / bytesTotal;
}

final class UpdateVerifying extends UpdateState {
  const UpdateVerifying({required this.targetVersion});

  final String targetVersion;
}

final class UpdateReady extends UpdateState {
  const UpdateReady({
    required this.targetVersion,
    required this.releaseNotesMarkdown,
    required this.stagedAt,
  });

  final String targetVersion;
  final String releaseNotesMarkdown;
  final DateTime stagedAt;
}

final class UpdateInstalling extends UpdateState {
  const UpdateInstalling({required this.targetVersion});

  final String targetVersion;
}

final class UpdateForced extends UpdateState {
  const UpdateForced({
    required this.targetVersion,
    required this.reason,
    required this.releaseNotesMarkdown,
  });

  final String targetVersion;

  /// Either `"minimum_version"` or `"blocklist"`.
  final String reason;
  final String releaseNotesMarkdown;
}

final class UpdateFailed extends UpdateState {
  const UpdateFailed({
    required this.userMessage,
    required this.technicalDetail,
  });

  /// Always safe to show directly in UI.
  final String userMessage;

  /// Logged only — never shown raw to the user.
  final String technicalDetail;
}

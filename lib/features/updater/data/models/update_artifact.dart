// lib/features/updater/data/models/update_artifact.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_artifact.g.dart';

@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateArtifact {
  const UpdateArtifact({
    required this.platform,
    required this.arch,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.ed25519Signature,
  });

  factory UpdateArtifact.fromJson(Map<String, Object?> json) =>
      _$UpdateArtifactFromJson(json);

  final String platform;
  final String arch;
  final String url;
  final int sizeBytes;
  final String sha256;
  final String ed25519Signature;

  Map<String, Object?> toJson() => _$UpdateArtifactToJson(this);
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

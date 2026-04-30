// lib/features/updater/data/models/brain_update_info.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'brain_update_info.g.dart';

@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class BrainUpdateInfo {
  const BrainUpdateInfo({
    required this.version,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.ed25519Signature,
  });

  factory BrainUpdateInfo.fromJson(Map<String, Object?> json) =>
      _$BrainUpdateInfoFromJson(json);

  final int version;
  final String url;
  final int sizeBytes;
  final String sha256;
  final String ed25519Signature;

  Map<String, Object?> toJson() => _$BrainUpdateInfoToJson(this);
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

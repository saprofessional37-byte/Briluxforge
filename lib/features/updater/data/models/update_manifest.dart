// lib/features/updater/data/models/update_manifest.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:briluxforge/features/updater/data/models/binary_update_info.dart';
import 'package:briluxforge/features/updater/data/models/brain_update_info.dart';
import 'package:briluxforge/features/updater/data/models/feature_flags_model.dart';
import 'package:briluxforge/features/updater/data/models/kill_switches_model.dart';

part 'update_manifest.g.dart';

@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UpdateManifest {
  const UpdateManifest({
    required this.manifestVersion,
    required this.publishedAt,
    this.binary,
    this.brain,
    required this.featureFlags,
    required this.killSwitches,
  });

  factory UpdateManifest.fromJson(Map<String, Object?> json) =>
      _$UpdateManifestFromJson(json);

  final int manifestVersion;
  final DateTime publishedAt;

  /// Absent when the manifest carries only a brain update.
  final BinaryUpdateInfo? binary;

  /// Absent when the manifest carries only a binary update.
  final BrainUpdateInfo? brain;

  final FeatureFlagsModel featureFlags;
  final KillSwitchesModel killSwitches;

  Map<String, Object?> toJson() => _$UpdateManifestToJson(this);
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

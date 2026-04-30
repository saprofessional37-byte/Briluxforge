// lib/features/updater/data/models/binary_update_info.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:briluxforge/features/updater/data/models/update_artifact.dart';

part 'binary_update_info.g.dart';

@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BinaryUpdateInfo {
  const BinaryUpdateInfo({
    required this.version,
    required this.minimumVersion,
    required this.blocklist,
    required this.releaseNotesMarkdown,
    required this.releaseNotesUrl,
    required this.artifacts,
  });

  factory BinaryUpdateInfo.fromJson(Map<String, Object?> json) =>
      _$BinaryUpdateInfoFromJson(json);

  final String version;
  final String minimumVersion;
  final List<String> blocklist;
  final String releaseNotesMarkdown;
  final String releaseNotesUrl;
  final List<UpdateArtifact> artifacts;

  Map<String, Object?> toJson() => _$BinaryUpdateInfoToJson(this);
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

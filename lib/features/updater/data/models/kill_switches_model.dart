// lib/features/updater/data/models/kill_switches_model.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kill_switches_model.g.dart';

@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class KillSwitchesModel {
  const KillSwitchesModel({
    required this.disabledModelIds,
    required this.disabledProviders,
    required this.disabledSkillIds,
  });

  const KillSwitchesModel.empty()
      : disabledModelIds = const [],
        disabledProviders = const [],
        disabledSkillIds = const [];

  factory KillSwitchesModel.fromJson(Map<String, Object?> json) =>
      _$KillSwitchesModelFromJson(json);

  final List<String> disabledModelIds;
  final List<String> disabledProviders;
  final List<String> disabledSkillIds;

  Map<String, Object?> toJson() => _$KillSwitchesModelToJson(this);
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

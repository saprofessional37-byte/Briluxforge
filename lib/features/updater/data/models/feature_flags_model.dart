// lib/features/updater/data/models/feature_flags_model.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.1

import 'package:flutter/foundation.dart';

// Does not use @JsonSerializable — the JSON value is itself a bare map with
// open-ended string keys. A fixed-schema generated class would silently drop
// unknown future flags instead of preserving them for getFlag() queries.
// Manual fromJson captures all keys; unknown flags default to false per §4.1.
@immutable
class FeatureFlagsModel {
  const FeatureFlagsModel(this._flags);

  const FeatureFlagsModel.empty() : _flags = const {};

  factory FeatureFlagsModel.fromJson(Map<String, Object?> json) =>
      FeatureFlagsModel(
        Map<String, bool>.fromEntries(
          json.entries.map(
            (e) => MapEntry(e.key, e.value as bool? ?? false),
          ),
        ),
      );

  final Map<String, bool> _flags;

  /// Returns the value of [key], or false if the key is absent or unrecognised.
  bool getFlag(String key) => _flags[key] ?? false;

  Map<String, Object?> toJson() => Map<String, Object?>.from(_flags);
}

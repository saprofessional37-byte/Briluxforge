// lib/features/delegation/providers/model_profiles_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';

part 'model_profiles_provider.g.dart';

/// Parsed, in-memory representation of assets/brain/model_profiles.json.
@immutable
class ModelProfilesData {
  const ModelProfilesData({
    required this.allModels,
    required this.routeableModels,
    required this.benchmarkModel,
    required this.safeFallbacks,
    required this.version,
  });

  /// Every model in the JSON, including the benchmark entry.
  final List<ModelProfile> allModels;

  /// Non-benchmark models only — safe to use for delegation routing.
  final List<ModelProfile> routeableModels;

  /// The entry marked `isBenchmark: true`. Used by the savings tracker.
  /// Null only if the JSON is malformed; callers use the hard-coded fallback.
  final ModelProfile? benchmarkModel;

  /// Ordered list of safe fallback model IDs for [DefaultModelReconciler].
  final List<String> safeFallbacks;

  final String version;
}

/// Loads and parses model_profiles.json from the app bundle.
/// Kept alive for the lifetime of the app — never reloaded unless the app
/// restarts with a new build (Smart Brain Update ships a new binary).
@Riverpod(keepAlive: true)
Future<ModelProfilesData> modelProfiles(Ref ref) async {
  final jsonString =
      await rootBundle.loadString('assets/brain/model_profiles.json');
  final raw = jsonDecode(jsonString) as Map<String, Object?>;

  final allModels = (raw['models'] as List<dynamic>)
      .map((e) => ModelProfile.fromJson(e as Map<String, Object?>))
      .toList();

  final benchmark = allModels.firstWhereOrNull((m) => m.isBenchmark);
  final routeable = allModels.where((m) => !m.isBenchmark).toList();

  final safeFallbacks = (raw['safeFallbacks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['gemini-2.0-flash', 'deepseek-chat', 'claude-sonnet-4-20250514'];

  return ModelProfilesData(
    allModels: allModels,
    routeableModels: routeable,
    benchmarkModel: benchmark,
    safeFallbacks: safeFallbacks,
    version: raw['version'] as String? ?? '1.0.0',
  );
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

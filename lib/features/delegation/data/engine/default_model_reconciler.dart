// lib/features/delegation/data/engine/default_model_reconciler.dart
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';

/// Reason why the reconciler changed the default model.
enum ReconcilerChangeReason {
  /// A safe fallback was found and the user has a connected API key for it.
  connectedFallback,

  /// A safe fallback was found but the user has no connected API key for it.
  noConnectedKey,

  /// No safe fallback found in the profile — used the first available model.
  lastResort,
}

/// Result returned by [DefaultModelReconciler.reconcile].
class ReconcilerResult {
  const ReconcilerResult._({
    required this.newModelId,
    required this.changed,
    this.reason,
    this.notificationMessage,
  });

  /// No change needed.
  const ReconcilerResult.unchanged(String currentId)
      : this._(newModelId: currentId, changed: false);

  /// The default was replaced.
  ReconcilerResult.changed({
    required String newModelId,
    required ReconcilerChangeReason reason,
    required String newModelDisplayName,
  }) : this._(
          newModelId: newModelId,
          changed: true,
          reason: reason,
          notificationMessage: switch (reason) {
            ReconcilerChangeReason.connectedFallback =>
              'Your previous default model is no longer supported. '
                  'We\'ve set $newModelDisplayName as your new default. '
                  'You can change this anytime in Settings.',
            ReconcilerChangeReason.noConnectedKey =>
              'Your previous default model is no longer supported. '
                  'We\'ve set $newModelDisplayName as your new default, '
                  'but you\'ll need to add an API key for it in Settings.',
            ReconcilerChangeReason.lastResort =>
              'Your previous default model is no longer supported. '
                  'We\'ve set $newModelDisplayName as your new default. '
                  'You can change this anytime in Settings.',
          },
        );

  final String newModelId;
  final bool changed;
  final ReconcilerChangeReason? reason;

  /// Dismissable notification message to show on the home screen.
  /// Null when [changed] is false.
  final String? notificationMessage;
}

/// Priority-ordered safe fallback model IDs.
/// Must match IDs in model_profiles.json.
const List<String> kSafeFallbacks = [
  'gemini-2.0-flash',
  'deepseek-chat',
  'claude-sonnet-4-20250514',
];

/// Pure, stateless reconciler. No Riverpod, no I/O.
///
/// Call [reconcile] on every app startup after model_profiles.json loads.
/// The caller (Riverpod provider) is responsible for persisting the result
/// and showing the notification to the user.
class DefaultModelReconciler {
  const DefaultModelReconciler();

  /// Checks whether [currentDefaultId] still exists in [availableModels].
  /// If not, selects a safe replacement and returns a [ReconcilerResult]
  /// describing the change.
  ///
  /// [availableModels] — non-benchmark models from the current model_profiles.json.
  /// [connectedProviders] — provider IDs with verified API keys.
  ReconcilerResult reconcile({
    required String? currentDefaultId,
    required List<ModelProfile> availableModels,
    required List<String> connectedProviders,
  }) {
    if (availableModels.isEmpty) {
      AppLogger.e('Reconciler',
          'model_profiles.json has no models — reconciler cannot proceed.');
      // Return unchanged so the app doesn't crash; caller handles the empty case.
      return ReconcilerResult.unchanged(currentDefaultId ?? 'deepseek-chat');
    }

    // Check if the current default still exists in the profile.
    if (currentDefaultId != null) {
      final stillExists =
          availableModels.any((m) => m.id == currentDefaultId);
      if (stillExists) {
        AppLogger.d('Reconciler',
            'Default model "$currentDefaultId" still exists. No reconciliation needed.');
        return ReconcilerResult.unchanged(currentDefaultId);
      }
    }

    AppLogger.w('Reconciler',
        'Default model "${currentDefaultId ?? 'null'}" not found in current profile. Reconciling.');

    // 1. Try safe fallbacks that the user has a connected API key for.
    for (final fallbackId in kSafeFallbacks) {
      final candidate =
          availableModels.firstWhereOrNull((m) => m.id == fallbackId);
      if (candidate == null) continue;
      if (connectedProviders.contains(candidate.provider)) {
        AppLogger.i('Reconciler',
            'Replacing with connected fallback: ${candidate.displayName}.');
        return ReconcilerResult.changed(
          newModelId: candidate.id,
          reason: ReconcilerChangeReason.connectedFallback,
          newModelDisplayName: candidate.displayName,
        );
      }
    }

    // 2. Try safe fallbacks without requiring a connected key.
    for (final fallbackId in kSafeFallbacks) {
      final candidate =
          availableModels.firstWhereOrNull((m) => m.id == fallbackId);
      if (candidate != null) {
        AppLogger.i('Reconciler',
            'Replacing with unconnected fallback: ${candidate.displayName}.');
        return ReconcilerResult.changed(
          newModelId: candidate.id,
          reason: ReconcilerChangeReason.noConnectedKey,
          newModelDisplayName: candidate.displayName,
        );
      }
    }

    // 3. Last resort: first available model in the profile.
    final first = availableModels.first;
    AppLogger.w('Reconciler',
        'Last-resort fallback: ${first.displayName}.');
    return ReconcilerResult.changed(
      newModelId: first.id,
      reason: ReconcilerChangeReason.lastResort,
      newModelDisplayName: first.displayName,
    );
  }
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

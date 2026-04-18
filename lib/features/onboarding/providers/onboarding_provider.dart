// lib/features/onboarding/providers/onboarding_provider.dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/services/shared_prefs_provider.dart';

part 'onboarding_provider.g.dart';

enum UseCaseType {
  coding,
  research,
  writing,
  building,
  general;

  String get defaultModelId => switch (this) {
        UseCaseType.coding => 'deepseek-chat',
        UseCaseType.research => 'gemini-2.0-flash',
        UseCaseType.writing => 'claude-sonnet-4-20250514',
        UseCaseType.building => 'deepseek-chat',
        UseCaseType.general => 'deepseek-chat',
      };

  String get displayName => switch (this) {
        UseCaseType.coding => 'Coding & Debugging',
        UseCaseType.research => 'Research & Analysis',
        UseCaseType.writing => 'Writing & Creative',
        UseCaseType.building => 'Building Apps & Websites',
        UseCaseType.general => 'A Little Bit of Everything',
      };

  String get description => switch (this) {
        UseCaseType.coding => 'Writing, reviewing, and fixing code',
        UseCaseType.research => 'Deep dives, summaries, and fact-finding',
        UseCaseType.writing => 'Essays, emails, stories, and content',
        UseCaseType.building => 'Full-stack development and architecture',
        UseCaseType.general => 'General assistant for all tasks',
      };
}

@immutable
class OnboardingState {
  const OnboardingState({
    required this.hasCompleted,
    this.selectedUseCase,
  });

  final bool hasCompleted;
  final UseCaseType? selectedUseCase;

  OnboardingState copyWith({
    bool? hasCompleted,
    UseCaseType? selectedUseCase,
  }) =>
      OnboardingState(
        hasCompleted: hasCompleted ?? this.hasCompleted,
        selectedUseCase: selectedUseCase ?? this.selectedUseCase,
      );
}

abstract final class _PrefsKeys {
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
  static const String selectedUseCase = 'selected_use_case';
  static const String defaultModelId = 'default_model_id';
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  Future<OnboardingState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _loadFromPrefs(prefs);
  }

  OnboardingState _loadFromPrefs(SharedPreferences prefs) {
    final hasCompleted =
        prefs.getBool(_PrefsKeys.hasCompletedOnboarding) ?? false;
    final useCaseRaw = prefs.getString(_PrefsKeys.selectedUseCase);
    final useCase = useCaseRaw != null
        ? UseCaseType.values
            .firstWhereOrNull((e) => e.name == useCaseRaw)
        : null;
    return OnboardingState(hasCompleted: hasCompleted, selectedUseCase: useCase);
  }

  Future<void> selectUseCase(UseCaseType useCase) async {
    final current =
        state.valueOrNull ?? const OnboardingState(hasCompleted: false);
    state = AsyncData(current.copyWith(selectedUseCase: useCase));
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_PrefsKeys.selectedUseCase, useCase.name);
    AppLogger.i('OnboardingProvider', 'Use case selected: ${useCase.name}');
  }

  Future<void> completeOnboarding() async {
    final current =
        state.valueOrNull ?? const OnboardingState(hasCompleted: false);
    state = AsyncData(current.copyWith(hasCompleted: true));
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_PrefsKeys.hasCompletedOnboarding, true);
    final defaultModel =
        current.selectedUseCase?.defaultModelId ?? 'deepseek-chat';
    await prefs.setString(_PrefsKeys.defaultModelId, defaultModel);
    AppLogger.i(
        'OnboardingProvider', 'Onboarding complete. Default model: $defaultModel');
  }
}

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// test/features/delegation/delegation_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/default_model_reconciler.dart';
import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/fallback_handler.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

// ── Test fixtures ──────────────────────────────────────────────────────────

/// A full set of non-benchmark models mirroring model_profiles.json.
final _allModels = <ModelProfile>[
  const ModelProfile(
    id: 'deepseek-chat',
    provider: 'deepseek',
    displayName: 'DeepSeek V3',
    strengths: ['coding', 'reasoning', 'math', 'debugging'],
    contextWindow: 65536,
    costPer1kInput: 0.00014,
    costPer1kOutput: 0.00028,
    tier: 'workhorse',
  ),
  const ModelProfile(
    id: 'gemini-2.0-flash',
    provider: 'google',
    displayName: 'Gemini 2.0 Flash',
    strengths: ['long_context', 'summarization', 'general', 'speed'],
    contextWindow: 1048576,
    costPer1kInput: 0.0000375,
    costPer1kOutput: 0.00015,
    tier: 'workhorse',
  ),
  const ModelProfile(
    id: 'claude-sonnet-4-20250514',
    provider: 'anthropic',
    displayName: 'Claude Sonnet 4',
    strengths: ['writing', 'analysis', 'nuance', 'instruction_following'],
    contextWindow: 200000,
    costPer1kInput: 0.003,
    costPer1kOutput: 0.015,
    tier: 'premium',
  ),
  const ModelProfile(
    id: 'gpt-4o',
    provider: 'openai',
    displayName: 'GPT-4o',
    strengths: ['reasoning', 'coding', 'general', 'vision'],
    contextWindow: 128000,
    costPer1kInput: 0.0025,
    costPer1kOutput: 0.01,
    tier: 'premium',
  ),
  const ModelProfile(
    id: 'llama-3.3-70b-versatile',
    provider: 'groq',
    displayName: 'Llama 3.3 70B (Groq)',
    strengths: ['speed', 'general', 'coding', 'reasoning'],
    contextWindow: 32768,
    costPer1kInput: 0.00059,
    costPer1kOutput: 0.00079,
    tier: 'workhorse',
  ),
];

const _allProviders = ['deepseek', 'google', 'anthropic', 'openai', 'groq'];

void main() {
  const engine = DelegationEngine();
  const reconciler = DefaultModelReconciler();

  // ══════════════════════════════════════════════════════════════════════════
  // DelegationEngine — Layer 1 tests
  // ══════════════════════════════════════════════════════════════════════════

  group('DelegationEngine.delegate()', () {
    // Test 1: coding prompt → DeepSeek (workhorse with 'coding' strength)
    test('T1: coding prompt routes to DeepSeek V3', () {
      final result = engine.delegate(
        prompt: 'debug this Python function — it throws a runtime error',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('deepseek-chat'));
      expect(result.selectedProvider, equals('deepseek'));
      expect(result.layerUsed, equals(1));
      expect(result.confidence,
          greaterThanOrEqualTo(0.70)); // must meet threshold
    });

    // Test 2: writing prompt → Claude Sonnet (only model with 'writing' strength)
    test('T2: writing prompt routes to Claude Sonnet 4', () {
      final result = engine.delegate(
        prompt: 'write a persuasive essay about renewable energy',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('claude-sonnet-4-20250514'));
      expect(result.selectedProvider, equals('anthropic'));
      expect(result.layerUsed, equals(1));
    });

    // Test 3: long context (> 30 000 tokens) → Gemini 2.0 Flash
    test('T3: long-context prompt routes to Gemini 2.0 Flash', () {
      // ~32 000 tokens * 4 chars = 128 000 characters
      final longPrompt = 'a ' * 64000;

      final result = engine.delegate(
        prompt: longPrompt,
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('gemini-2.0-flash'));
      expect(result.selectedProvider, equals('google'));
      expect(result.layerUsed, equals(1));
      expect(result.confidence, equals(1.0));
    });

    // Test 4: single model connected → always routes to that model, confidence 1.0
    test('T4: single connected model always wins, confidence 1.0', () {
      final result = engine.delegate(
        prompt: 'explain the theory of relativity',
        availableModels: _allModels,
        connectedProviders: ['google'], // only Gemini connected
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('gemini-2.0-flash'));
      expect(result.confidence, equals(1.0));
      expect(result.layerUsed, equals(1));
    });

    // Test 5: no connected model → returns null
    test('T5: no connected models returns null', () {
      final result = engine.delegate(
        prompt: 'write a function to sort a list',
        availableModels: _allModels,
        connectedProviders: [],
      );

      expect(result, isNull);
    });

    // Test 6: low-confidence / ambiguous prompt → returns null (triggers dialog)
    test('T6: low-confidence prompt returns null', () {
      // "hello" has no keyword matrix matches — score = 0, below 0.70 threshold
      final result = engine.delegate(
        prompt: 'hello',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNull);
    });

    // Test 7: wasOverridden defaults to false on a fresh Layer 1 result
    test('T7: Layer 1 result has wasOverridden=false by default', () {
      final result = engine.delegate(
        prompt: 'debug this SQL query',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.wasOverridden, isFalse);
      expect(result.userChoseDefault, isFalse);
    });

    // Test 8: copyWith override flag — simulates the user picking a different model
    test('T8: override flag is set via copyWith (manual override flow)', () {
      final original = engine.delegate(
        prompt: 'implement a binary search algorithm in Dart',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      )!;

      // Simulate user choosing Gemini manually.
      final overridden = original.copyWith(
        selectedModelId: 'gemini-2.0-flash',
        selectedProvider: 'google',
        wasOverridden: true,
        reasoning: 'Manual override: user selected Gemini 2.0 Flash.',
      );

      expect(overridden.wasOverridden, isTrue);
      expect(overridden.selectedModelId, equals('gemini-2.0-flash'));
      expect(overridden.layerUsed, equals(1)); // layer unchanged by override
    });

    // Test 9: default from onboarding (coding use-case → deepseek-chat)
    test('T9: onboarding coding use-case default model matches Layer 3 output',
        () {
      // Layer 3 should return the onboarding-set default when there's no Layer 1 match.
      // Simulate the user choosing "Use Default" after a failed delegation.
      final mockSecureStorage = _FakeSecureStorage();
      final handler = FallbackHandler(
        secureStorage: mockSecureStorage,
      );

      // Default model from coding onboarding is 'deepseek-chat'.
      const defaultModelId = 'deepseek-chat';

      final result = handler.layer3Default(
        defaultModelId: defaultModelId,
        availableModels: _allModels,
        connectedProviders: _allProviders,
        userChoseDefault: true,
      );

      expect(result.selectedModelId, equals('deepseek-chat'));
      expect(result.selectedProvider, equals('deepseek'));
      expect(result.layerUsed, equals(3));
      expect(result.userChoseDefault, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // DefaultModelReconciler tests
  // ══════════════════════════════════════════════════════════════════════════

  group('DefaultModelReconciler.reconcile()', () {
    // Test 10: default model was removed → reconciles to first connected safe fallback
    test('T10: removed default → replaced with first connected safe fallback',
        () {
      const removedId = 'old-model-that-was-removed';
      final modelsWithoutOld = _allModels
          .where((m) => m.id != removedId)
          .toList(); // all current models (old one is gone)

      final result = reconciler.reconcile(
        currentDefaultId: removedId,
        availableModels: modelsWithoutOld,
        connectedProviders: ['google'], // only Gemini connected
      );

      expect(result.changed, isTrue);
      // Gemini Flash is the first safe fallback and user has a key for it.
      expect(result.newModelId, equals('gemini-2.0-flash'));
      expect(result.reason, equals(ReconcilerChangeReason.connectedFallback));
      expect(result.notificationMessage, isNotNull);
    });

    // Test 11: removed default, no connected fallback → picks safe fallback without key
    test('T11: removed default + no connected fallback → picks unconnected safe fallback',
        () {
      const removedId = 'old-model-that-was-removed';

      final result = reconciler.reconcile(
        currentDefaultId: removedId,
        availableModels: _allModels,
        connectedProviders: [], // nothing connected
      );

      expect(result.changed, isTrue);
      // gemini-2.0-flash is the first safe fallback (no key required at this step).
      expect(result.newModelId, equals('gemini-2.0-flash'));
      expect(result.reason, equals(ReconcilerChangeReason.noConnectedKey));
    });

    // Test 12: catastrophic — empty model profile → unchanged (no crash)
    test('T12: empty model profile → no crash, returns unchanged', () {
      final result = reconciler.reconcile(
        currentDefaultId: 'deepseek-chat',
        availableModels: [], // catastrophic empty profile
        connectedProviders: _allProviders,
      );

      // The reconciler must never crash and must not return null.
      expect(result, isNotNull);
      expect(result.changed, isFalse);
      expect(result.newModelId, isNotNull);
    });

    // Bonus test: current default still exists → no change
    test('T_bonus: valid default still in profile → no reconciliation', () {
      final result = reconciler.reconcile(
        currentDefaultId: 'deepseek-chat',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result.changed, isFalse);
      expect(result.newModelId, equals('deepseek-chat'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ContextAnalyzer tests
  // ══════════════════════════════════════════════════════════════════════════

  group('ContextAnalyzer', () {
    const analyzer = ContextAnalyzer();

    test('short prompt is not long context', () {
      final result = analyzer.analyze('debug this function');
      expect(result.isLongContext, isFalse);
      expect(result.isHugeContext, isFalse);
    });

    test('long prompt (>30k tokens) triggers long context flag', () {
      // 30001 tokens * 4 chars = 120 004 chars
      final result = analyzer.analyze('a ' * 60002);
      expect(result.isLongContext, isTrue);
      expect(result.isHugeContext, isFalse);
    });

    test('huge prompt (>100k tokens) triggers huge context flag', () {
      // 100001 tokens * 4 chars = 400 004 chars
      final result = analyzer.analyze('a ' * 200002);
      expect(result.isHugeContext, isTrue);
      expect(result.isLongContext, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FallbackHandler Layer 3 edge cases
  // ══════════════════════════════════════════════════════════════════════════

  group('FallbackHandler.layer3Default()', () {
    test('returns connected model when default is not connected', () {
      final handler = FallbackHandler(secureStorage: _FakeSecureStorage());

      final result = handler.layer3Default(
        defaultModelId: 'claude-sonnet-4-20250514', // anthropic not connected
        availableModels: _allModels,
        connectedProviders: ['deepseek'], // only deepseek connected
      );

      // Falls back to any connected model.
      expect(result.selectedModelId, equals('deepseek-chat'));
      expect(result.layerUsed, equals(3));
    });

    test('userChoseDefault flag is propagated', () {
      final handler = FallbackHandler(secureStorage: _FakeSecureStorage());

      final result = handler.layer3Default(
        defaultModelId: 'deepseek-chat',
        availableModels: _allModels,
        connectedProviders: ['deepseek'],
        userChoseDefault: true,
      );

      expect(result.userChoseDefault, isTrue);
    });
  });
}

// ── Test doubles ───────────────────────────────────────────────────────────

/// Subclass of SecureStorageService that overrides all I/O methods.
/// Layer 3 never reads keys, so returning null is always safe here.
/// Layer 2 HTTP calls are not exercised in these unit tests.
class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readKey(String provider) async => null;

  @override
  Future<void> storeKey(String provider, String key) async {}

  @override
  Future<void> deleteKey(String provider) async {}

  @override
  Future<void> deleteAll() async {}
}

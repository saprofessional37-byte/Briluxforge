// test/features/delegation/delegation_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/default_model_reconciler.dart';
import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/fallback_handler.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

// ── Test fixtures (Phase 13 canonical strengths) ────────────────────────────

final _allModels = <ModelProfile>[
  const ModelProfile(
    id: 'deepseek-chat',
    provider: 'deepseek',
    displayName: 'DeepSeek V3',
    strengths: ['coding', 'debugging', 'math_reasoning', 'high_volume_cheap'],
    contextWindow: 65536,
    costPer1kInput: 0.00014,
    costPer1kOutput: 0.00028,
    tier: 'workhorse',
    latencyHintMs: 1800,
    descriptionForAdmin: 'Cost-efficient coding and math specialist.',
  ),
  const ModelProfile(
    id: 'gemini-2.0-flash',
    provider: 'google',
    displayName: 'Gemini 2.0 Flash',
    strengths: ['long_context', 'summarization', 'high_volume_cheap', 'multilingual'],
    contextWindow: 1048576,
    costPer1kInput: 0.0000375,
    costPer1kOutput: 0.00015,
    tier: 'workhorse',
    latencyHintMs: 900,
    descriptionForAdmin: 'Ultra-long context window summarization model.',
  ),
  const ModelProfile(
    id: 'claude-sonnet-4-20250514',
    provider: 'anthropic',
    displayName: 'Claude Sonnet 4',
    strengths: [
      'analysis',
      'creative_writing',
      'professional_writing',
      'instruction_following',
      'safety_critical',
    ],
    contextWindow: 200000,
    costPer1kInput: 0.003,
    costPer1kOutput: 0.015,
    tier: 'premium',
    latencyHintMs: 2200,
    descriptionForAdmin: 'Premium reasoning, writing, and safety-critical model.',
  ),
  const ModelProfile(
    id: 'gpt-4o',
    provider: 'openai',
    displayName: 'GPT-4o',
    strengths: ['coding', 'analysis', 'instruction_following', 'math_reasoning', 'multilingual'],
    contextWindow: 128000,
    costPer1kInput: 0.0025,
    costPer1kOutput: 0.01,
    tier: 'premium',
    latencyHintMs: 2400,
    descriptionForAdmin: 'Versatile premium model with broad coding and analysis strengths.',
  ),
  const ModelProfile(
    id: 'llama-3.3-70b-versatile',
    provider: 'groq',
    displayName: 'Llama 3.3 70B (Groq)',
    strengths: ['low_latency', 'general', 'coding'],
    contextWindow: 32768,
    costPer1kInput: 0.00059,
    costPer1kOutput: 0.00079,
    tier: 'specialist',
    latencyHintMs: 280,
    descriptionForAdmin: 'Groq-hosted ultra-fast inference specialist.',
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
    // T1: debugging prompt → DeepSeek (debugging + coding keywords; debugging wins)
    test('T1: debugging prompt routes to DeepSeek V3', () {
      final result = engine.delegate(
        prompt: 'debug this Python function — it throws a runtime error',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('deepseek-chat'));
      expect(result.selectedProvider, equals('deepseek'));
      expect(result.layerUsed, equals(1));
      expect(result.confidence, greaterThanOrEqualTo(0.05));
    });

    // T2: professional-writing prompt → Claude Sonnet 4 (only model with that strength)
    test('T2: professional-writing prompt routes to Claude Sonnet 4', () {
      final result = engine.delegate(
        prompt: 'draft a blog post about renewable energy',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('claude-sonnet-4-20250514'));
      expect(result.selectedProvider, equals('anthropic'));
      expect(result.layerUsed, equals(1));
    });

    // T3: long context (> 30 000 tokens) → Gemini 2.0 Flash (largest context window)
    test('T3: long-context prompt routes to Gemini 2.0 Flash', () {
      final longPrompt = 'a ' * 64000; // ~32 000 tokens * 4 chars = 128 000 chars

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

    // T4: single model connected → always routes to that model, confidence 1.0
    test('T4: single connected model always wins, confidence 1.0', () {
      final result = engine.delegate(
        prompt: 'explain the theory of relativity',
        availableModels: _allModels,
        connectedProviders: ['google'],
      );

      expect(result, isNotNull);
      expect(result!.selectedModelId, equals('gemini-2.0-flash'));
      expect(result.confidence, equals(1.0));
      expect(result.layerUsed, equals(1));
    });

    // T5: no connected models → returns null
    test('T5: no connected models returns null', () {
      final result = engine.delegate(
        prompt: 'write a function to sort a list',
        availableModels: _allModels,
        connectedProviders: [],
      );

      expect(result, isNull);
    });

    // T6: no keyword matches → normalizedScores empty → null (triggers dialog)
    test('T6: prompt with no keyword matches returns null', () {
      final result = engine.delegate(
        prompt: 'hello',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      );

      expect(result, isNull);
    });

    // T7: wasOverridden defaults to false on a fresh Layer 1 result
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

    // T8: copyWith override flag — simulates the user picking a different model
    test('T8: override flag is set via copyWith (manual override flow)', () {
      final original = engine.delegate(
        prompt: 'implement a binary search algorithm in Dart',
        availableModels: _allModels,
        connectedProviders: _allProviders,
      )!;

      final overridden = original.copyWith(
        selectedModelId: 'gemini-2.0-flash',
        selectedProvider: 'google',
        wasOverridden: true,
        reasoning: 'Manual override: user selected Gemini 2.0 Flash.',
      );

      expect(overridden.wasOverridden, isTrue);
      expect(overridden.selectedModelId, equals('gemini-2.0-flash'));
      expect(overridden.layerUsed, equals(1));
    });

    // T9: Layer 3 default from onboarding (coding use-case → deepseek-chat)
    test('T9: onboarding coding use-case default model matches Layer 3 output', () {
      final handler = FallbackHandler(secureStorage: _FakeSecureStorage());

      final result = handler.layer3Default(
        defaultModelId: 'deepseek-chat',
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
    // T10: removed default → reconciles to first connected safe fallback
    test('T10: removed default → replaced with first connected safe fallback', () {
      const removedId = 'old-model-that-was-removed';
      final modelsWithoutOld =
          _allModels.where((m) => m.id != removedId).toList();

      final result = reconciler.reconcile(
        currentDefaultId: removedId,
        availableModels: modelsWithoutOld,
        connectedProviders: ['google'],
      );

      expect(result.changed, isTrue);
      expect(result.newModelId, equals('gemini-2.0-flash'));
      expect(result.reason, equals(ReconcilerChangeReason.connectedFallback));
      expect(result.notificationMessage, isNotNull);
    });

    // T11: removed default + no connected fallback → safe fallback without key
    test('T11: removed default + no connected fallback → picks unconnected safe fallback', () {
      const removedId = 'old-model-that-was-removed';

      final result = reconciler.reconcile(
        currentDefaultId: removedId,
        availableModels: _allModels,
        connectedProviders: [],
      );

      expect(result.changed, isTrue);
      expect(result.newModelId, equals('gemini-2.0-flash'));
      expect(result.reason, equals(ReconcilerChangeReason.noConnectedKey));
    });

    // T12: empty model profile → no crash, returns unchanged
    test('T12: empty model profile → no crash, returns unchanged', () {
      final result = reconciler.reconcile(
        currentDefaultId: 'deepseek-chat',
        availableModels: [],
        connectedProviders: _allProviders,
      );

      expect(result, isNotNull);
      expect(result.changed, isFalse);
      expect(result.newModelId, isNotNull);
    });

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
      final result = analyzer.analyze('a ' * 60002); // ~30 001 tokens
      expect(result.isLongContext, isTrue);
      expect(result.isHugeContext, isFalse);
    });

    test('huge prompt (>100k tokens) triggers huge context flag', () {
      final result = analyzer.analyze('a ' * 200002); // ~100 001 tokens
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
        defaultModelId: 'claude-sonnet-4-20250514',
        availableModels: _allModels,
        connectedProviders: ['deepseek'],
      );

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


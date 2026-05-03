// test/features/savings/savings_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';
import 'package:briluxforge/features/savings/data/repositories/savings_calculator.dart';

// ── Test fixtures ─────────────────────────────────────────────────────────────

const ModelProfile _deepseek = ModelProfile(
  id: 'deepseek-chat',
  provider: 'deepseek',
  displayName: 'DeepSeek V3',
  strengths: ['coding'],
  contextWindow: 65536,
  costPer1kInput: 0.00014,
  costPer1kOutput: 0.00028,
  tier: 'workhorse',
  latencyHintMs: 1800,
  descriptionForAdmin: 'Cost-efficient coding specialist.',
);

const ModelProfile _opusBenchmark = ModelProfile(
  id: 'claude-opus-4-6',
  provider: 'anthropic',
  displayName: 'Claude Opus 4.6',
  strengths: [],
  contextWindow: 200000,
  costPer1kInput: 0.005,
  costPer1kOutput: 0.025,
  tier: 'premium',
  latencyHintMs: 3500,
  descriptionForAdmin: 'Benchmark-only model.',
  isBenchmark: true,
);

// A hypothetical model more expensive than Opus on output.
const ModelProfile _superExpensive = ModelProfile(
  id: 'mega-model',
  provider: 'fictional',
  displayName: 'Mega Model',
  strengths: [],
  contextWindow: 1000,
  costPer1kInput: 0.010,
  costPer1kOutput: 0.050,
  tier: 'premium',
  latencyHintMs: 999,
  descriptionForAdmin: 'Hypothetical expensive model for testing.',
);

const _calculator = SavingsCalculator();

// ── Helpers ───────────────────────────────────────────────────────────────────

SavingsModel _modelWithOneDeepseekCall({
  int inputTokens = 5000,
  int outputTokens = 2000,
}) =>
    SavingsModel.empty().addCall(
      modelId: 'deepseek-chat',
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SavingsCalculator', () {
    // Test 1: Single DeepSeek call — exact savings value
    test(
      'DeepSeek 5000 input + 2000 output tokens yields savings ≈ \$0.0737',
      () {
        final model = _modelWithOneDeepseekCall();

        final snapshot = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        // actualCost  = (5000 × 0.00014 / 1000) + (2000 × 0.00028 / 1000)
        //             = 0.0007 + 0.00056 = 0.00126
        // benchCost   = (5000 × 0.005   / 1000) + (2000 × 0.025   / 1000)
        //             = 0.025  + 0.05   = 0.075
        // savings     = 0.075 − 0.00126 = 0.07374
        expect(snapshot.totalSaved, closeTo(0.07374, 0.00001));
        expect(snapshot.totalCalls, equals(1));
      },
    );

    // Test 2: 1 000 identical calls scale linearly
    test(
      '1 000 identical DeepSeek calls → cumulative savings ≈ \$73.74',
      () {
        SavingsModel model = SavingsModel.empty();
        for (int i = 0; i < 1000; i++) {
          model = model.addCall(
            modelId: 'deepseek-chat',
            inputTokens: 5000,
            outputTokens: 2000,
          );
        }

        final snapshot = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        expect(snapshot.totalSaved, closeTo(73.74, 0.01));
        expect(snapshot.totalCalls, equals(1000));
      },
    );

    // Test 3: Routing to Opus itself → savings = 0, never decreases
    test(
      'Routing to Opus itself produces zero savings; cumulative never decreases',
      () {
        // One DeepSeek call first (establishes positive savings baseline).
        SavingsModel model = SavingsModel.empty().addCall(
          modelId: 'deepseek-chat',
          inputTokens: 5000,
          outputTokens: 2000,
        );

        final snapshotBefore = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        // Now route a call to Opus itself.
        model = model.addCall(
          modelId: 'claude-opus-4-6',
          inputTokens: 5000,
          outputTokens: 2000,
        );

        final snapshotAfter = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        // Opus call contributes 0 savings (benchmark cost == actual cost).
        expect(
          snapshotAfter.totalSaved,
          closeTo(snapshotBefore.totalSaved, 0.00001),
        );

        // Total savings must not decrease.
        expect(snapshotAfter.totalSaved, greaterThanOrEqualTo(snapshotBefore.totalSaved));
      },
    );

    // Test 4: Model more expensive than Opus → per-call savings clamped to 0
    test(
      'Model more expensive than Opus yields zero savings (clamped, not negative)',
      () {
        final model = SavingsModel.empty().addCall(
          modelId: 'mega-model',
          inputTokens: 5000,
          outputTokens: 2000,
        );

        final snapshot = _calculator.compute(
          model: model,
          allProfiles: [_superExpensive, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        // actualCost = (5000×0.010/1000) + (2000×0.050/1000) = 0.05 + 0.10 = 0.15
        // benchCost  = 0.075
        // savings    = clamp(0.075 - 0.15, 0, ∞) = 0
        expect(snapshot.totalSaved, equals(0.0));
        expect(snapshot.totalSaved, greaterThanOrEqualTo(0.0));
      },
    );

    // Test 5: Benchmark missing from profiles → hard-coded fallback used
    test(
      'Missing benchmark entry uses hard-coded Opus 4.6 fallback and yields correct savings',
      () {
        final model = _modelWithOneDeepseekCall();

        // Pass null benchmarkModel to simulate missing entry.
        final snapshot = _calculator.compute(
          model: model,
          allProfiles: [_deepseek],
          benchmarkModel: null,
        );

        // Fallback constants are 0.005 input / 0.025 output — same as Opus.
        // Result should match test 1.
        expect(snapshot.totalSaved, closeTo(0.07374, 0.00001));
        expect(snapshot.benchmarkDisplayName, equals('Claude Opus 4.6'));
      },
    );

    // Test 6: Smart Brain Update changing benchmark pricing recalculates correctly
    test(
      'Stored token counts recalculate correctly when benchmark price changes',
      () {
        final model = _modelWithOneDeepseekCall(
          
        );

        const ModelProfile opusAtOldPrice = _opusBenchmark;

        const ModelProfile opusAtNewPrice = ModelProfile(
          id: 'claude-opus-4-6',
          provider: 'anthropic',
          displayName: 'Claude Opus 4.6',
          strengths: [],
          contextWindow: 200000,
          costPer1kInput: 0.006,  // $1 higher per 1M input
          costPer1kOutput: 0.030, // $5 higher per 1M output
          tier: 'premium',
          latencyHintMs: 3500,
          descriptionForAdmin: 'Benchmark-only model at new price point.',
          isBenchmark: true,
        );

        final snapshotOld = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, opusAtOldPrice],
          benchmarkModel: opusAtOldPrice,
        );

        final snapshotNew = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, opusAtNewPrice],
          benchmarkModel: opusAtNewPrice,
        );

        // Higher benchmark price → larger savings.
        expect(snapshotNew.totalSaved, greaterThan(snapshotOld.totalSaved));

        // New benchmark cost = (5000×0.006/1000) + (2000×0.030/1000)
        //                    = 0.030 + 0.060 = 0.090
        // New savings        = 0.090 - 0.00126 = 0.08874
        expect(snapshotNew.totalSaved, closeTo(0.08874, 0.00001));
      },
    );

    // Test 7: Calculator uses the exact token values it receives — not estimates
    test(
      'Calculator math uses provided inputTokens/outputTokens exactly',
      () {
        // Provide specific token counts and verify the output is exactly right.
        // This confirms the calculator does not substitute or re-estimate values.
        const int exactInput = 7_777;
        const int exactOutput = 3_333;

        final model = SavingsModel.empty().addCall(
          modelId: 'deepseek-chat',
          inputTokens: exactInput,
          outputTokens: exactOutput,
        );

        final snapshot = _calculator.compute(
          model: model,
          allProfiles: [_deepseek, _opusBenchmark],
          benchmarkModel: _opusBenchmark,
        );

        const double expectedActual =
            (exactInput * 0.00014 / 1000) + (exactOutput * 0.00028 / 1000);
        const double expectedBenchmark =
            (exactInput * 0.005 / 1000) + (exactOutput * 0.025 / 1000);
        const double expectedSavings = expectedBenchmark - expectedActual;

        expect(snapshot.totalActualCost, closeTo(expectedActual, 1e-10));
        expect(snapshot.totalBenchmarkCost, closeTo(expectedBenchmark, 1e-10));
        expect(snapshot.totalSaved, closeTo(expectedSavings, 1e-10));
        expect(snapshot.totalInputTokens, equals(exactInput));
        expect(snapshot.totalOutputTokens, equals(exactOutput));
      },
    );

    // Bonus: per-model breakdown is populated correctly
    test('perModelBreakdown contains correct entry for each model used', () {
      final model = SavingsModel.empty()
          .addCall(
            modelId: 'deepseek-chat',
            inputTokens: 5000,
            outputTokens: 2000,
          )
          .addCall(
            modelId: 'deepseek-chat',
            inputTokens: 1000,
            outputTokens: 500,
          );

      final snapshot = _calculator.compute(
        model: model,
        allProfiles: [_deepseek, _opusBenchmark],
        benchmarkModel: _opusBenchmark,
      );

      expect(snapshot.perModelBreakdown, hasLength(1));
      expect(snapshot.perModelBreakdown.first.modelId, equals('deepseek-chat'));
      expect(snapshot.perModelBreakdown.first.callCount, equals(2));
      expect(snapshot.perModelBreakdown.first.inputTokens, equals(6000));
      expect(snapshot.perModelBreakdown.first.outputTokens, equals(2500));
    });
  });
}

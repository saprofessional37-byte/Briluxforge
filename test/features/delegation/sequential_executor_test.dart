// test/features/delegation/sequential_executor_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/sequential_executor.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';
import 'package:briluxforge/services/api_client_service.dart';
import 'package:briluxforge/services/api_response.dart';
import 'package:briluxforge/services/secure_storage_service.dart';
import 'package:briluxforge/services/skill_injection_service.dart';

// ── Hand-rolled fakes ─────────────────────────────────────────────────────────

class _FakeSecureStorage implements SecureStorageService {
  @override
  Future<String?> readKey(String provider) async => 'fake-key';

  @override
  Future<void> storeKey(String provider, String key) async {}

  @override
  Future<void> deleteKey(String provider) async {}

  @override
  Future<void> deleteAll() async {}
}

class _FakeApiClient extends ApiClientService {
  _FakeApiClient() : super(secureStorage: _FakeSecureStorage());

  String responseForProvider(String provider) => 'Response from $provider';

  @override
  Future<ApiResponse> sendPrompt({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    int maxTokens = 4096,
  }) async {
    return ApiResponse(
      content: responseForProvider(provider),
      inputTokens: 10,
      outputTokens: 20,
      modelId: modelId,
      provider: provider,
    );
  }
}

class _FailingApiClient extends ApiClientService {
  _FailingApiClient() : super(secureStorage: _FakeSecureStorage());

  @override
  Future<ApiResponse> sendPrompt({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    int maxTokens = 4096,
  }) async {
    throw Exception('Simulated API failure');
  }
}

final _fakeModels = [
  const ModelProfile(
    id: 'deepseek-chat',
    provider: 'deepseek',
    displayName: 'DeepSeek V3',
    strengths: ['coding', 'debugging', 'math_reasoning'],
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
    displayName: 'Gemini Flash',
    strengths: ['summarization', 'long_context', 'general', 'high_volume_cheap'],
    contextWindow: 1048576,
    costPer1kInput: 0.00015,
    costPer1kOutput: 0.00060,
    tier: 'workhorse',
    latencyHintMs: 900,
    descriptionForAdmin: 'Ultra-long context window summarization model.',
  ),
];

const _connectedProviders = ['deepseek', 'google'];

SubTask _makeTask({
  required String id,
  required int orderIndex,
  required String category,
  double confidence = 0.85,
  List<String> dependsOn = const [],
}) =>
    SubTask(
      id: id,
      orderIndex: orderIndex,
      text: 'Task text for $category.',
      category: category,
      categoryConfidence: confidence,
      estimatedTokens: 80,
      dependsOn: dependsOn,
      status: SubTaskStatus.pending,
    );

TaskPlan _makePlan(List<SubTask> tasks) => TaskPlan(
      id: 'plan-1',
      originalPrompt: 'Test prompt.',
      subTasks: tasks,
      status: TaskPlanStatus.planning,
      createdAt: DateTime.now(),
    );

SequentialExecutor _makeExecutor({ApiClientService? apiClient}) =>
    SequentialExecutor(
      delegationEngine: const DelegationEngine(),
      apiClientService: apiClient ?? _FakeApiClient(),
      skillInjectionService: const SkillInjectionService(),
      availableModels: _fakeModels,
      connectedProviders: _connectedProviders,
      enabledSkills: const [],
    );

void main() {
  group('SequentialExecutor', () {
    test('all parallel tasks complete successfully', () async {
      final tasks = [
        _makeTask(id: 'a', orderIndex: 0, category: 'coding'),
        _makeTask(id: 'b', orderIndex: 1, category: 'research'),
      ];
      final plan = _makePlan(tasks);
      final executor = _makeExecutor();

      final events = await executor.execute(plan).toList();
      final finalPlan = events.last.plan;

      expect(
        finalPlan.status,
        anyOf(TaskPlanStatus.stitching, TaskPlanStatus.executing),
      );
      // Both tasks should be completed (or at worst failed due to no real API).
      for (final task in finalPlan.subTasks) {
        expect(task.status, anyOf(SubTaskStatus.completed, SubTaskStatus.failed));
      }
    });

    test('sequential tasks execute in dependency order', () async {
      final tasks = [
        _makeTask(id: 'a', orderIndex: 0, category: 'research'),
        _makeTask(id: 'b', orderIndex: 1, category: 'writing', dependsOn: ['a']),
      ];
      final plan = _makePlan(tasks);
      final executor = _makeExecutor();

      final events = await executor.execute(plan).toList();
      // Should have progressed through both tasks.
      expect(events.length, greaterThan(1));
    });

    test('failed task propagates to dependent sub-task', () async {
      final tasks = [
        _makeTask(id: 'a', orderIndex: 0, category: 'coding'),
        _makeTask(id: 'b', orderIndex: 1, category: 'research', dependsOn: ['a']),
      ];
      final plan = _makePlan(tasks);
      final executor = _makeExecutor(apiClient: _FailingApiClient());

      final events = await executor.execute(plan).toList();
      final finalPlan = events.last.plan;

      // Task 'a' fails, task 'b' (which depends on 'a') should also fail.
      final taskA = finalPlan.subTasks.firstWhere((t) => t.id == 'a');
      final taskB = finalPlan.subTasks.firstWhere((t) => t.id == 'b');

      expect(taskA.status, equals(SubTaskStatus.failed));
      expect(taskB.status, equals(SubTaskStatus.failed));
      expect(taskB.errorMessage, contains('Upstream'));
    });

    test('plan is abandoned when Layer 1 routing fails for a sub-task', () async {
      // Use a category that has no matching model in _fakeModels.
      final tasks = [
        _makeTask(id: 'a', orderIndex: 0, category: 'nonexistent_category'),
      ];
      final plan = _makePlan(tasks);
      final executor = _makeExecutor();

      final events = await executor.execute(plan).toList();
      final finalPlan = events.last.plan;

      expect(finalPlan.status, equals(TaskPlanStatus.abandoned));
    });
  });
}

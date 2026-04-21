// lib/features/delegation/data/models/task_plan.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/models/sub_task.dart';

enum TaskPlanStatus { planning, executing, stitching, completed, failed, abandoned }

@immutable
class TaskPlan extends Equatable {
  const TaskPlan({
    required this.id,
    required this.originalPrompt,
    required this.subTasks,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String originalPrompt;
  final List<SubTask> subTasks;
  final TaskPlanStatus status;
  final DateTime createdAt;

  TaskPlan copyWith({
    String? id,
    String? originalPrompt,
    List<SubTask>? subTasks,
    TaskPlanStatus? status,
    DateTime? createdAt,
  }) =>
      TaskPlan(
        id: id ?? this.id,
        originalPrompt: originalPrompt ?? this.originalPrompt,
        subTasks: subTasks ?? this.subTasks,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new plan with the matching sub-task replaced (by id).
  TaskPlan replaceSubTask(SubTask updated) {
    return copyWith(
      subTasks: subTasks.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  @override
  List<Object?> get props => [id, originalPrompt, subTasks, status, createdAt];
}

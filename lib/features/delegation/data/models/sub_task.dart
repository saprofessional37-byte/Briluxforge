// lib/features/delegation/data/models/sub_task.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/engine/task_segmenter.dart';

enum SubTaskStatus { pending, routing, running, completed, failed }

@immutable
class SubTask extends Equatable {
  const SubTask({
    required this.id,
    required this.orderIndex,
    required this.text,
    required this.category,
    required this.categoryConfidence,
    required this.estimatedTokens,
    required this.dependsOn,
    required this.status,
    this.selectedModelId,
    this.selectedProvider,
    this.response,
    this.errorMessage,
  });

  factory SubTask.fromCandidate(
    SegmentCandidate c, {
    required String id,
    required int orderIndex,
  }) =>
      SubTask(
        id: id,
        orderIndex: orderIndex,
        text: c.text,
        category: c.category,
        categoryConfidence: c.categoryConfidence,
        estimatedTokens: c.estimatedTokens,
        dependsOn: const [],
        status: SubTaskStatus.pending,
      );

  final String id;
  final int orderIndex;
  final String text;
  final String category;
  final double categoryConfidence;
  final int estimatedTokens;
  final List<String> dependsOn;
  final SubTaskStatus status;
  final String? selectedModelId;
  final String? selectedProvider;
  final String? response;
  final String? errorMessage;

  SubTask copyWith({
    String? id,
    int? orderIndex,
    String? text,
    String? category,
    double? categoryConfidence,
    int? estimatedTokens,
    List<String>? dependsOn,
    SubTaskStatus? status,
    String? selectedModelId,
    String? selectedProvider,
    String? response,
    String? errorMessage,
  }) =>
      SubTask(
        id: id ?? this.id,
        orderIndex: orderIndex ?? this.orderIndex,
        text: text ?? this.text,
        category: category ?? this.category,
        categoryConfidence: categoryConfidence ?? this.categoryConfidence,
        estimatedTokens: estimatedTokens ?? this.estimatedTokens,
        dependsOn: dependsOn ?? this.dependsOn,
        status: status ?? this.status,
        selectedModelId: selectedModelId ?? this.selectedModelId,
        selectedProvider: selectedProvider ?? this.selectedProvider,
        response: response ?? this.response,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        id,
        orderIndex,
        text,
        category,
        categoryConfidence,
        estimatedTokens,
        dependsOn,
        status,
        selectedModelId,
        selectedProvider,
        response,
        errorMessage,
      ];
}

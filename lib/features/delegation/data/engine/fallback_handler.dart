// lib/features/delegation/data/engine/fallback_handler.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:briluxforge/core/constants/api_constants.dart';
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

@immutable
class _ClassificationResult {
  const _ClassificationResult({
    required this.category,
    required this.confidence,
  });

  final String category;
  final double confidence;
}

/// Handles Layer 2 (API-assisted triage) and Layer 3 (default fallback).
///
/// Layer 2 sends a short classification meta-prompt to the user's most capable
/// connected model and maps the response to a model choice.
/// Layer 3 always succeeds — it returns the user's configured default model.
class FallbackHandler {
  FallbackHandler({
    required SecureStorageService secureStorage,
    http.Client? httpClient,
  })  : _secureStorage = secureStorage,
        _httpClient = httpClient ?? http.Client();

  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  static const String _classifierSystemPrompt =
      'You are a task classifier. Given the user\'s message below, respond with ONLY '
      'a JSON object: {"category": "<one of: coding, reasoning, math, writing, '
      'summarization, long_context, general>", "confidence": <0.0-1.0>}. Do not explain.';

  // ── Layer 2 ────────────────────────────────────────────────────────────────

  /// Sends a classification meta-prompt to the most capable connected model.
  ///
  /// Returns null when:
  /// - No capable connected model is found.
  /// - The API call fails.
  /// - JSON parsing fails or confidence < [AppConstants.apiTiageConfidenceThreshold].
  Future<DelegationResult?> layer2Classify({
    required String prompt,
    required List<ModelProfile> availableModels,
    required List<String> connectedProviders,
    required String defaultModelId,
  }) async {
    final capable = _findMostCapable(availableModels, connectedProviders);
    if (capable == null) {
      AppLogger.w('FallbackHandler', 'Layer 2: no capable connected model found.');
      return null;
    }

    final apiKey = await _secureStorage.readKey(capable.provider);
    if (apiKey == null) {
      AppLogger.w('FallbackHandler',
          'Layer 2: no API key for ${capable.provider}.');
      return null;
    }

    final truncated = prompt.length > AppConstants.apiTriageMaxPromptChars
        ? prompt.substring(0, AppConstants.apiTriageMaxPromptChars)
        : prompt;

    try {
      final raw = await _sendClassificationRequest(
        model: capable,
        apiKey: apiKey,
        userMessage: truncated,
      );
      if (raw == null) return null;

      final classification = _parseClassification(raw);
      if (classification == null) {
        AppLogger.w('FallbackHandler', 'Layer 2: failed to parse classification JSON.');
        return null;
      }

      if (classification.confidence < AppConstants.apiTiageConfidenceThreshold) {
        AppLogger.d('FallbackHandler',
            'Layer 2: confidence ${classification.confidence} below threshold.');
        return null;
      }

      final chosen = _mapCategoryToModel(
        classification.category,
        availableModels,
        connectedProviders,
      );
      if (chosen == null) return null;

      AppLogger.i('FallbackHandler',
          'Layer 2: category=${classification.category} → ${chosen.displayName}.');

      return DelegationResult(
        selectedModelId: chosen.id,
        selectedProvider: chosen.provider,
        layerUsed: 2,
        confidence: classification.confidence,
        reasoning:
            'AI routing via ${capable.displayName}: ${classification.category} task '
            'detected (confidence: ${(classification.confidence * 100).toStringAsFixed(0)}%).',
      );
    } catch (e) {
      AppLogger.w('FallbackHandler', 'Layer 2 classification failed: $e');
      return null;
    }
  }

  // ── Layer 3 ────────────────────────────────────────────────────────────────

  /// Always succeeds. Returns the user's configured default model.
  ///
  /// Fallback chain:
  /// 1. User's default model if connected.
  /// 2. Any other connected non-benchmark model.
  /// 3. First non-benchmark model in profiles (user may need to add a key).
  DelegationResult layer3Default({
    required String defaultModelId,
    required List<ModelProfile> availableModels,
    required List<String> connectedProviders,
    bool userChoseDefault = false,
  }) {
    final nonBenchmark =
        availableModels.where((m) => !m.isBenchmark).toList();

    // 1. Preferred: user's default if it's connected.
    ModelProfile? chosen = nonBenchmark.firstWhereOrNull(
      (m) =>
          m.id == defaultModelId && connectedProviders.contains(m.provider),
    );

    // 2. Any connected model.
    chosen ??= nonBenchmark.firstWhereOrNull(
      (m) => connectedProviders.contains(m.provider),
    );

    // 3. First model in profiles regardless of key (shouldn't happen in practice).
    chosen ??= nonBenchmark.firstOrNull;

    final modelId = chosen?.id ?? defaultModelId;
    final provider = chosen?.provider ?? 'unknown';
    final name = chosen?.displayName ?? defaultModelId;

    AppLogger.i('FallbackHandler', 'Layer 3: default fallback → $name.');

    return DelegationResult(
      selectedModelId: modelId,
      selectedProvider: provider,
      layerUsed: 3,
      confidence: 1.0,
      reasoning: 'Default fallback: routed to $name.',
      userChoseDefault: userChoseDefault,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns the most capable connected model: premium > workhorse.
  ModelProfile? _findMostCapable(
    List<ModelProfile> models,
    List<String> connectedProviders,
  ) {
    final connected = models
        .where((m) => !m.isBenchmark && connectedProviders.contains(m.provider))
        .toList();
    if (connected.isEmpty) return null;
    return connected.firstWhereOrNull((m) => m.isPremium) ??
        connected.firstOrNull;
  }

  /// Maps a category string to the best connected model for that category.
  ModelProfile? _mapCategoryToModel(
    String category,
    List<ModelProfile> availableModels,
    List<String> connectedProviders,
  ) {
    final connected = availableModels
        .where((m) => !m.isBenchmark && connectedProviders.contains(m.provider))
        .toList();

    final matching =
        connected.where((m) => m.strengths.contains(category)).toList();
    if (matching.isEmpty) return connected.firstOrNull;

    // Prefer workhorse for cost.
    return matching.firstWhereOrNull((m) => m.isWorkhorse) ??
        matching.firstOrNull;
  }

  _ClassificationResult? _parseClassification(String raw) {
    try {
      // Strip markdown code fences if the model wrapped the JSON.
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, Object?>;
      final category = json['category'] as String?;
      final confidence = (json['confidence'] as num?)?.toDouble();
      if (category == null || confidence == null) return null;
      return _ClassificationResult(
        category: category,
        confidence: confidence.clamp(0.0, 1.0),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Provider-specific HTTP requests ───────────────────────────────────────

  Future<String?> _sendClassificationRequest({
    required ModelProfile model,
    required String apiKey,
    required String userMessage,
  }) async {
    return switch (model.provider) {
      ApiConstants.providerDeepseek ||
      ApiConstants.providerOpenai ||
      ApiConstants.providerGroq =>
        _sendOpenAICompatible(model, apiKey, userMessage),
      ApiConstants.providerAnthropic =>
        _sendAnthropic(model, apiKey, userMessage),
      ApiConstants.providerGoogle => _sendGemini(model, apiKey, userMessage),
      _ => null,
    };
  }

  Future<String?> _sendOpenAICompatible(
    ModelProfile model,
    String apiKey,
    String userMessage,
  ) async {
    final baseUrl = switch (model.provider) {
      ApiConstants.providerDeepseek => ApiConstants.deepseekBaseUrl,
      ApiConstants.providerGroq => ApiConstants.groqBaseUrl,
      _ => ApiConstants.openaiBaseUrl,
    };

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model.id,
            'messages': [
              {'role': 'system', 'content': _classifierSystemPrompt},
              {'role': 'user', 'content': userMessage},
            ],
            'max_tokens': 100,
            'temperature': 0,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return null;
    final message =
        (choices[0] as Map<String, Object?>)['message'] as Map<String, Object?>?;
    return message?['content'] as String?;
  }

  Future<String?> _sendAnthropic(
    ModelProfile model,
    String apiKey,
    String userMessage,
  ) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConstants.anthropicBaseUrl}/messages'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': ApiConstants.anthropicVersion,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model.id,
            'max_tokens': 100,
            'system': _classifierSystemPrompt,
            'messages': [
              {'role': 'user', 'content': userMessage},
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final content = json['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) return null;
    return (content[0] as Map<String, Object?>)['text'] as String?;
  }

  Future<String?> _sendGemini(
    ModelProfile model,
    String apiKey,
    String userMessage,
  ) async {
    final uri = Uri.parse(
      '${ApiConstants.geminiBaseUrl}/models/${model.id}:generateContent',
    ).replace(queryParameters: {'key': apiKey});

    final response = await _httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': userMessage},
                ],
              },
            ],
            'systemInstruction': {
              'parts': [
                {'text': _classifierSystemPrompt},
              ],
            },
            'generationConfig': {
              'maxOutputTokens': 100,
              'temperature': 0,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;
    final content =
        (candidates[0] as Map<String, Object?>)['content'] as Map<String, Object?>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    return (parts[0] as Map<String, Object?>)['text'] as String?;
  }
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

// lib/services/api_client_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/core/constants/api_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/services/api_response.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

part 'api_client_service.g.dart';

/// Sends prompts to all supported AI providers and returns streaming or
/// non-streaming responses. This is the ONLY file that makes prompt-carrying
/// HTTP calls — all API key handling is done via [SecureStorageService].
class ApiClientService {
  const ApiClientService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  static const int _defaultMaxTokens = 4096;
  static const Duration _requestTimeout = Duration(seconds: 120);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a stream of [ApiStreamEvent]s:
  ///   • [ApiStreamDelta]    — incremental text chunk
  ///   • [ApiStreamComplete] — terminal success; includes [ApiResponse] with
  ///                           exact token counts from the provider's JSON
  ///   • [ApiStreamError]    — terminal failure
  ///
  /// If streaming fails before any content is emitted, automatically falls
  /// back to a non-streaming request for the same provider and model.
  Stream<ApiStreamEvent> sendPromptStreaming({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    int maxTokens = _defaultMaxTokens,
  }) async* {
    final String? apiKey = await _secureStorage.readKey(provider);
    if (apiKey == null) {
      yield ApiStreamError(ApiKeyNotFoundException(provider));
      return;
    }

    bool hasYieldedContent = false;

    try {
      await for (final ApiStreamEvent event in _stream(
        provider: provider,
        modelId: modelId,
        messages: messages,
        systemPrompt: systemPrompt,
        apiKey: apiKey,
        maxTokens: maxTokens,
      )) {
        if (event is ApiStreamDelta) hasYieldedContent = true;
        yield event;
      }
    } catch (e) {
      final AppException exc = _wrapException(e, provider, apiKey);

      if (!hasYieldedContent) {
        AppLogger.w(
          'ApiClient',
          'Streaming failed before content was received — attempting '
          'non-streaming fallback. Error: ${exc.message}',
        );
        try {
          final ApiResponse response = await _send(
            provider: provider,
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          );
          yield ApiStreamComplete(response: response);
        } catch (fallbackErr) {
          yield ApiStreamError(_wrapException(fallbackErr, provider, apiKey));
        }
      } else {
        yield ApiStreamError(exc);
      }
    }
  }

  /// Non-streaming request. Returns the full [ApiResponse] once the provider
  /// finishes generating. Use [sendPromptStreaming] for chat UX.
  Future<ApiResponse> sendPrompt({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    int maxTokens = _defaultMaxTokens,
  }) async {
    final String? apiKey = await _secureStorage.readKey(provider);
    if (apiKey == null) throw ApiKeyNotFoundException(provider);

    try {
      return await _send(
        provider: provider,
        modelId: modelId,
        messages: messages,
        systemPrompt: systemPrompt,
        apiKey: apiKey,
        maxTokens: maxTokens,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw _wrapException(e, provider, apiKey);
    }
  }

  // ── Dispatch Helpers ───────────────────────────────────────────────────────

  Stream<ApiStreamEvent> _stream({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) =>
      switch (provider) {
        ApiConstants.providerDeepseek ||
        ApiConstants.providerOpenai ||
        ApiConstants.providerGroq =>
          _streamOpenAICompatible(
            provider: provider,
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        ApiConstants.providerAnthropic => _streamAnthropic(
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        ApiConstants.providerGoogle => _streamGemini(
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        _ => throw ApiRequestException(
            provider: provider,
            message: 'Unsupported provider: $provider',
          ),
      };

  Future<ApiResponse> _send({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) =>
      switch (provider) {
        ApiConstants.providerDeepseek ||
        ApiConstants.providerOpenai ||
        ApiConstants.providerGroq =>
          _sendOpenAICompatible(
            provider: provider,
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        ApiConstants.providerAnthropic => _sendAnthropic(
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        ApiConstants.providerGoogle => _sendGemini(
            modelId: modelId,
            messages: messages,
            systemPrompt: systemPrompt,
            apiKey: apiKey,
            maxTokens: maxTokens,
          ),
        _ => throw ApiRequestException(
            provider: provider,
            message: 'Unsupported provider: $provider',
          ),
      };

  // ── OpenAI-Compatible Streaming (DeepSeek / OpenAI / Groq) ────────────────

  Stream<ApiStreamEvent> _streamOpenAICompatible({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async* {
    final Uri uri = Uri.parse('${_baseUrl(provider)}/chat/completions');
    final Map<String, String> headers = _openAIHeaders(apiKey);
    final Map<String, Object?> body = _openAIBody(
      modelId: modelId,
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      stream: true,
    );

    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final http.StreamedResponse streamedResponse =
          await client.send(request).timeout(_requestTimeout);

      if (streamedResponse.statusCode != 200) {
        final String raw = await streamedResponse.stream.bytesToString();
        throw _openAIHttpError(provider, streamedResponse.statusCode, raw, apiKey);
      }

      final StringBuffer contentBuffer = StringBuffer();
      int inputTokens = 0;
      int outputTokens = 0;

      await for (final String line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final String data = line.substring(6).trim();
        if (data == '[DONE]') break;

        try {
          final Map<String, Object?> json =
              jsonDecode(data) as Map<String, Object?>;

          // usage is populated in the final chunk when stream_options is set
          if (json['usage'] case final Map<String, Object?> usage) {
            inputTokens = (usage['prompt_tokens'] as int?) ?? inputTokens;
            outputTokens = (usage['completion_tokens'] as int?) ?? outputTokens;
          }

          final List<dynamic>? choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;

          final Map<String, Object?>? delta =
              (choices.first as Map<String, Object?>)['delta']
                  as Map<String, Object?>?;
          final String? content = delta?['content'] as String?;

          if (content != null && content.isNotEmpty) {
            contentBuffer.write(content);
            yield ApiStreamDelta(content);
          }
        } catch (e) {
          AppLogger.w('ApiClient', 'Skipping malformed SSE chunk: $e');
        }
      }

      yield ApiStreamComplete(
        response: ApiResponse(
          content: contentBuffer.toString(),
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          modelId: modelId,
          provider: provider,
        ),
      );
    } finally {
      client.close();
    }
  }

  // ── OpenAI-Compatible Non-Streaming ────────────────────────────────────────

  Future<ApiResponse> _sendOpenAICompatible({
    required String provider,
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async {
    final Uri uri = Uri.parse('${_baseUrl(provider)}/chat/completions');
    final Map<String, String> headers = _openAIHeaders(apiKey);
    final Map<String, Object?> body = _openAIBody(
      modelId: modelId,
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      stream: false,
    );

    final http.Response response = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw _openAIHttpError(provider, response.statusCode, response.body, apiKey);
    }

    final Map<String, Object?> json =
        jsonDecode(response.body) as Map<String, Object?>;
    final Map<String, Object?> message =
        ((json['choices'] as List).first as Map<String, Object?>)['message']
            as Map<String, Object?>;
    final Map<String, Object?>? usage = json['usage'] as Map<String, Object?>?;

    return ApiResponse(
      content: message['content'] as String? ?? '',
      inputTokens: (usage?['prompt_tokens'] as int?) ?? 0,
      outputTokens: (usage?['completion_tokens'] as int?) ?? 0,
      modelId: modelId,
      provider: provider,
    );
  }

  // ── Anthropic Streaming ────────────────────────────────────────────────────

  Stream<ApiStreamEvent> _streamAnthropic({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async* {
    final Uri uri = Uri.parse('${ApiConstants.anthropicBaseUrl}/messages');
    final Map<String, String> headers = _anthropicHeaders(apiKey);
    final Map<String, Object?> body = _anthropicBody(
      modelId: modelId,
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      stream: true,
    );

    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final http.StreamedResponse streamedResponse =
          await client.send(request).timeout(_requestTimeout);

      if (streamedResponse.statusCode != 200) {
        final String raw = await streamedResponse.stream.bytesToString();
        throw _anthropicHttpError(streamedResponse.statusCode, raw, apiKey);
      }

      final StringBuffer contentBuffer = StringBuffer();
      int inputTokens = 0;
      int outputTokens = 0;

      await for (final String line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        // Track event type from the preceding "event:" line
        if (line.startsWith('event: ')) continue; // handled via data.type field
        if (!line.startsWith('data: ')) continue;

        final String data = line.substring(6).trim();
        try {
          final Map<String, Object?> json =
              jsonDecode(data) as Map<String, Object?>;
          final String? type = json['type'] as String?;

          switch (type) {
            case 'message_start':
              // input_tokens arrives here — the authoritative count
              final Map<String, Object?>? msgUsage =
                  (json['message'] as Map<String, Object?>?)?['usage']
                      as Map<String, Object?>?;
              inputTokens = (msgUsage?['input_tokens'] as int?) ?? 0;

            case 'content_block_delta':
              final Map<String, Object?>? delta =
                  json['delta'] as Map<String, Object?>?;
              final String? text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                contentBuffer.write(text);
                yield ApiStreamDelta(text);
              }

            case 'message_delta':
              // output_tokens arrives here — the authoritative count
              final Map<String, Object?>? deltaUsage =
                  json['usage'] as Map<String, Object?>?;
              outputTokens = (deltaUsage?['output_tokens'] as int?) ?? outputTokens;
          }
        } catch (e) {
          AppLogger.w('ApiClient', 'Skipping malformed Anthropic SSE chunk: $e');
        }
      }

      yield ApiStreamComplete(
        response: ApiResponse(
          content: contentBuffer.toString(),
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          modelId: modelId,
          provider: ApiConstants.providerAnthropic,
        ),
      );
    } finally {
      client.close();
    }
  }

  // ── Anthropic Non-Streaming ────────────────────────────────────────────────

  Future<ApiResponse> _sendAnthropic({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async {
    final Uri uri = Uri.parse('${ApiConstants.anthropicBaseUrl}/messages');
    final Map<String, String> headers = _anthropicHeaders(apiKey);
    final Map<String, Object?> body = _anthropicBody(
      modelId: modelId,
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      stream: false,
    );

    final http.Response response = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw _anthropicHttpError(response.statusCode, response.body, apiKey);
    }

    final Map<String, Object?> json =
        jsonDecode(response.body) as Map<String, Object?>;
    final List<dynamic> content = json['content'] as List<dynamic>;
    final String text = content
        .map((part) => (part as Map<String, Object?>)['text'] as String? ?? '')
        .join();
    final Map<String, Object?>? usage = json['usage'] as Map<String, Object?>?;

    return ApiResponse(
      content: text,
      inputTokens: (usage?['input_tokens'] as int?) ?? 0,
      outputTokens: (usage?['output_tokens'] as int?) ?? 0,
      modelId: modelId,
      provider: ApiConstants.providerAnthropic,
    );
  }

  // ── Google Gemini Streaming ────────────────────────────────────────────────

  Stream<ApiStreamEvent> _streamGemini({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async* {
    final Uri uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelId:streamGenerateContent').replace(queryParameters: {'key': apiKey, 'alt': 'sse'});

    final Map<String, String> headers = {'content-type': 'application/json'};
    final Map<String, Object?> body = _geminiBody(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );

    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final http.StreamedResponse streamedResponse =
          await client.send(request).timeout(_requestTimeout);

      if (streamedResponse.statusCode != 200) {
        final String raw = await streamedResponse.stream.bytesToString();
        throw _geminiHttpError(streamedResponse.statusCode, raw, apiKey);
      }

      final StringBuffer contentBuffer = StringBuffer();
      int inputTokens = 0;
      int outputTokens = 0;

      await for (final String line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final String data = line.substring(6).trim();

        try {
          final Map<String, Object?> json =
              jsonDecode(data) as Map<String, Object?>;

          // usageMetadata is in every chunk; last chunk has the final totals
          if (json['usageMetadata'] case final Map<String, Object?> meta) {
            inputTokens =
                (meta['promptTokenCount'] as int?) ?? inputTokens;
            outputTokens =
                (meta['candidatesTokenCount'] as int?) ?? outputTokens;
          }

          final List<dynamic>? candidates =
              json['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) continue;

          final Map<String, Object?>? content =
              (candidates.first as Map<String, Object?>)['content']
                  as Map<String, Object?>?;
          final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
          if (parts == null) continue;

          for (final Object? part in parts) {
            final String? text =
                (part as Map<String, Object?>)['text'] as String?;
            if (text != null && text.isNotEmpty) {
              contentBuffer.write(text);
              yield ApiStreamDelta(text);
            }
          }
        } catch (e) {
          AppLogger.w('ApiClient', 'Skipping malformed Gemini SSE chunk: $e');
        }
      }

      yield ApiStreamComplete(
        response: ApiResponse(
          content: contentBuffer.toString(),
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          modelId: modelId,
          provider: ApiConstants.providerGoogle,
        ),
      );
    } finally {
      client.close();
    }
  }

  // ── Google Gemini Non-Streaming ────────────────────────────────────────────

  Future<ApiResponse> _sendGemini({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String apiKey,
    required int maxTokens,
  }) async {
    final Uri uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent').replace(queryParameters: {'key': apiKey});

    final Map<String, String> headers = {'content-type': 'application/json'};
    final Map<String, Object?> body = _geminiBody(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );

    final http.Response response = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw _geminiHttpError(response.statusCode, response.body, apiKey);
    }

    final Map<String, Object?> json =
        jsonDecode(response.body) as Map<String, Object?>;
    final List<dynamic>? candidates = json['candidates'] as List<dynamic>?;
    final Map<String, Object?>? firstCandidate =
        candidates?.first as Map<String, Object?>?;
    final Map<String, Object?>? content =
        firstCandidate?['content'] as Map<String, Object?>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    final String text = parts
            ?.map((p) => (p as Map<String, Object?>)['text'] as String? ?? '')
            .join() ??
        '';
    final Map<String, Object?>? meta =
        json['usageMetadata'] as Map<String, Object?>?;

    return ApiResponse(
      content: text,
      inputTokens: (meta?['promptTokenCount'] as int?) ?? 0,
      outputTokens: (meta?['candidatesTokenCount'] as int?) ?? 0,
      modelId: modelId,
      provider: ApiConstants.providerGoogle,
    );
  }

  // ── Request Builders ───────────────────────────────────────────────────────

  String _baseUrl(String provider) => switch (provider) {
        ApiConstants.providerDeepseek => ApiConstants.deepseekBaseUrl,
        ApiConstants.providerOpenai => ApiConstants.openaiBaseUrl,
        ApiConstants.providerGroq => ApiConstants.groqBaseUrl,
        _ => throw ApiRequestException(
            provider: provider,
            message: 'No base URL for provider: $provider',
          ),
      };

  Map<String, String> _openAIHeaders(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      };

  Map<String, String> _anthropicHeaders(String apiKey) => {
        'x-api-key': apiKey,
        'anthropic-version': ApiConstants.anthropicVersion,
        'content-type': 'application/json',
      };

  Map<String, Object?> _openAIBody({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int maxTokens,
    required bool stream,
  }) {
    final List<Map<String, String>> apiMessages = [];
    if (systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final ChatMessage m in messages) {
      if (m.role != 'system') {
        apiMessages.add({'role': m.role, 'content': m.content});
      }
    }

    return {
      'model': modelId,
      'messages': apiMessages,
      'max_tokens': maxTokens,
      'stream': stream,
      // stream_options ensures usage is included in the final streaming chunk
      if (stream) 'stream_options': {'include_usage': true},
    };
  }

  Map<String, Object?> _anthropicBody({
    required String modelId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int maxTokens,
    required bool stream,
  }) {
    final List<Map<String, String>> apiMessages = messages
        .where((m) => m.role != 'system')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    return {
      'model': modelId,
      'max_tokens': maxTokens,
      if (stream) 'stream': true,
      if (systemPrompt.isNotEmpty) 'system': systemPrompt,
      'messages': apiMessages,
    };
  }

  Map<String, Object?> _geminiBody({
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int maxTokens,
  }) {
    // Gemini uses 'model' for the assistant role
    final List<Map<String, Object?>> contents = messages
        .where((m) => m.role != 'system')
        .map(
          (m) => {
            'role': m.role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m.content},
            ],
          },
        )
        .toList();

    return {
      'contents': contents,
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      'generationConfig': {'maxOutputTokens': maxTokens},
    };
  }

  // ── Error Handling ─────────────────────────────────────────────────────────

  ApiRequestException _openAIHttpError(
    String provider,
    int statusCode,
    String raw,
    String apiKey,
  ) {
    final String sanitized = _sanitizeError(raw, apiKey);
    return ApiRequestException(
      provider: provider,
      statusCode: statusCode,
      message: _friendlyHttpError(_providerDisplayName(provider), statusCode),
      rawResponseBody: sanitized,
    );
  }

  ApiRequestException _anthropicHttpError(
    int statusCode,
    String raw,
    String apiKey,
  ) {
    final String sanitized = _sanitizeError(raw, apiKey);
    return ApiRequestException(
      provider: ApiConstants.providerAnthropic,
      statusCode: statusCode,
      message: _friendlyHttpError('Anthropic', statusCode),
      rawResponseBody: sanitized,
    );
  }

  ApiRequestException _geminiHttpError(
    int statusCode,
    String raw,
    String apiKey,
  ) {
    final String sanitized = _sanitizeError(raw, apiKey);
    return ApiRequestException(
      provider: ApiConstants.providerGoogle,
      statusCode: statusCode,
      message: _friendlyHttpError('Google Gemini', statusCode),
      rawResponseBody: sanitized,
    );
  }

  String _friendlyHttpError(String name, int statusCode) =>
      switch (statusCode) {
        400 => "Couldn't process the request for $name. "
            'The message may be too long or malformed. Try a shorter prompt.',
        401 => 'Invalid API key for $name. '
            "Double-check that you copied the full key from the provider's dashboard. "
            'Open Settings → API Keys → $name to update it.',
        403 => 'Access denied by $name. '
            'Your account may not have API access enabled. '
            "Check your account status on the provider's dashboard.",
        429 => 'Rate limit reached for $name. '
            'Your key is valid — wait a moment and try again.',
        500 || 502 || 503 => '$name is experiencing issues right now. '
            'This is on their end — try again in a few minutes.',
        _ => "Couldn't connect to $name (HTTP $statusCode). "
            'Check your internet connection and try again.',
      };

  /// Replaces the raw API key with [REDACTED] in error strings so it is
  /// never exposed in logs or user-facing messages.
  String _sanitizeError(String error, String apiKey) =>
      error.replaceAll(apiKey, '[REDACTED]');

  String _providerDisplayName(String provider) => switch (provider) {
        ApiConstants.providerDeepseek => 'DeepSeek',
        ApiConstants.providerOpenai => 'OpenAI',
        ApiConstants.providerGroq => 'Groq',
        ApiConstants.providerAnthropic => 'Anthropic',
        ApiConstants.providerGoogle => 'Google Gemini',
        _ => provider,
      };

  AppException _wrapException(Object e, String provider, String apiKey) {
    if (e is AppException) return e;
    return ApiRequestException(
      provider: provider,
      message: _sanitizeError(e.toString(), apiKey),
    );
  }
}

@riverpod
ApiClientService apiClientService(Ref ref) {
  final SecureStorageService secureStorage =
      ref.watch(secureStorageServiceProvider);
  return ApiClientService(secureStorage: secureStorage);
}

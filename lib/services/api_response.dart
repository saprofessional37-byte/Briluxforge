// lib/services/api_response.dart

import 'package:flutter/foundation.dart';

/// A single message in a conversation, as sent to an API provider.
@immutable
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  /// 'user' | 'assistant' | 'system'
  final String role;
  final String content;
}

/// The fully resolved response from any provider after a successful API call.
@immutable
class ApiResponse {
  const ApiResponse({
    required this.content,
    required this.inputTokens,
    required this.outputTokens,
    required this.modelId,
    required this.provider,
  });

  final String content;

  /// Exact value from the provider's usage JSON — never estimated.
  final int inputTokens;

  /// Exact value from the provider's usage JSON — never estimated.
  final int outputTokens;

  final String modelId;
  final String provider;
}

/// Sealed event hierarchy for streaming responses.
sealed class ApiStreamEvent {
  const ApiStreamEvent();
}

/// A text delta chunk received during streaming.
final class ApiStreamDelta extends ApiStreamEvent {
  const ApiStreamDelta(this.content);
  final String content;
}

/// Terminal success event: streaming complete, includes the full response with
/// exact token counts sourced from the provider's usage fields.
final class ApiStreamComplete extends ApiStreamEvent {
  const ApiStreamComplete({required this.response});
  final ApiResponse response;
}

/// An error occurred during streaming. Contains the wrapped [AppException].
final class ApiStreamError extends ApiStreamEvent {
  const ApiStreamError(this.error);
  final Exception error;
}

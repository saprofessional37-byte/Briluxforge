// lib/core/constants/api_constants.dart

abstract final class ApiConstants {
  // DeepSeek
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String deepseekChatModel = 'deepseek-chat';

  // Google Gemini
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiFlashModel = 'gemini-2.0-flash';

  // Anthropic
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicVersion = '2023-06-01';
  static const String claudeSonnetModel = 'claude-sonnet-4-20250514';
  static const String claudeOpusBenchmarkModel = 'claude-opus-4-6';

  // OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String gpt4oModel = 'gpt-4o';

  // Groq
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqLlamaModel = 'llama-3.3-70b-versatile';

  // Provider IDs (must match model_profiles.json)
  static const String providerDeepseek = 'deepseek';
  static const String providerGoogle = 'google';
  static const String providerAnthropic = 'anthropic';
  static const String providerOpenai = 'openai';
  static const String providerGroq = 'groq';

  // Pricing benchmark — Opus 4.6 hard-coded fallback
  static const double benchmarkInputPer1k = 0.005;
  static const double benchmarkOutputPer1k = 0.025;
  static const String benchmarkDisplayName = 'Claude Opus 4.6';
  static const String benchmarkModelId = 'claude-opus-4-6';
}

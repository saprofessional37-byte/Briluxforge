// lib/features/api_keys/data/repositories/api_key_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:briluxforge/core/constants/api_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

class ApiKeyRepository {
  const ApiKeyRepository({
    required SecureStorageService secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;

  final SecureStorageService _secureStorage;
  final SharedPreferences _prefs;

  static const String _metaKeyPrefix = 'api_key_meta_';

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<List<ApiKeyModel>> loadAll() async {
    final List<ApiKeyModel> keys = [];
    for (final provider in kSupportedProviders) {
      final raw = _prefs.getString('$_metaKeyPrefix${provider.id}');
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        keys.add(ApiKeyModel.fromJson(map));
      } catch (e) {
        AppLogger.w(
          'ApiKeyRepo',
          'Corrupt metadata for ${provider.id} — skipping. Error: $e',
        );
      }
    }
    return keys;
  }

  /// Persists both the raw key (secure storage) and the metadata (prefs).
  Future<void> save(ApiKeyModel model, String rawKey) async {
    await _secureStorage.storeKey(model.provider, rawKey);
    await _prefs.setString(
      '$_metaKeyPrefix${model.provider}',
      jsonEncode(model.toJson()),
    );
  }

  /// Updates only metadata — does not touch the raw key in secure storage.
  Future<void> updateMeta(ApiKeyModel model) async {
    await _prefs.setString(
      '$_metaKeyPrefix${model.provider}',
      jsonEncode(model.toJson()),
    );
  }

  Future<void> delete(String provider) async {
    await _secureStorage.deleteKey(provider);
    await _prefs.remove('$_metaKeyPrefix$provider');
  }

  // ── Verification ───────────────────────────────────────────────────────────

  Future<void> verifyKey(String provider) async {
    final key = await _secureStorage.readKey(provider);
    if (key == null) throw ApiKeyNotFoundException(provider);

    switch (provider) {
      case ApiConstants.providerDeepseek:
        await _verifyBearer(
          '${ApiConstants.deepseekBaseUrl}/models',
          key,
          provider,
        );
      case ApiConstants.providerGoogle:
        await _verifyGemini(key);
      case ApiConstants.providerAnthropic:
        await _verifyAnthropic(key);
      case ApiConstants.providerOpenai:
        await _verifyBearer(
          '${ApiConstants.openaiBaseUrl}/models',
          key,
          provider,
        );
      case ApiConstants.providerGroq:
        await _verifyBearer(
          '${ApiConstants.groqBaseUrl}/models',
          key,
          provider,
        );
      default:
        throw ApiRequestException(
          provider: provider,
          message: 'Unknown provider "$provider". Cannot verify.',
        );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _verifyBearer(
    String url,
    String key,
    String provider,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $key'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;
      throw _httpError(provider, response.statusCode);
    } on ApiRequestException {
      rethrow;
    } catch (e) {
      throw ApiRequestException(
        provider: provider,
        message: _networkErrorMessage(_displayName(provider)),
      );
    }
  }

  Future<void> _verifyGemini(String key) async {
    try {
      final uri = Uri.parse('${ApiConstants.geminiBaseUrl}/models')
          .replace(queryParameters: {'key': key});
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;
      throw _httpError(ApiConstants.providerGoogle, response.statusCode);
    } on ApiRequestException {
      rethrow;
    } catch (e) {
      throw ApiRequestException(
        provider: ApiConstants.providerGoogle,
        message: _networkErrorMessage('Google Gemini'),
      );
    }
  }

  Future<void> _verifyAnthropic(String key) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.anthropicBaseUrl}/messages'),
            headers: {
              'x-api-key': key,
              'anthropic-version': ApiConstants.anthropicVersion,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': 'claude-haiku-4-5-20251001',
              'max_tokens': 1,
              'messages': [
                {'role': 'user', 'content': 'hi'},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;
      throw _httpError(ApiConstants.providerAnthropic, response.statusCode);
    } on ApiRequestException {
      rethrow;
    } catch (e) {
      throw ApiRequestException(
        provider: ApiConstants.providerAnthropic,
        message: _networkErrorMessage('Anthropic'),
      );
    }
  }

  ApiRequestException _httpError(String provider, int statusCode) {
    final name = _displayName(provider);
    return ApiRequestException(
      provider: provider,
      statusCode: statusCode,
      message: switch (statusCode) {
        401 => 'Invalid API key for $name. '
            "Double-check that you copied the full key from the provider's dashboard.",
        403 => 'Access denied by $name. '
            'Your account may not have API access enabled yet.',
        429 => 'Rate limit hit on $name. '
            'Your key is valid — wait a moment and tap Verify again.',
        _ => 'Couldn\'t connect to $name (HTTP $statusCode). '
            'Check your internet connection and try again.',
      },
    );
  }

  String _networkErrorMessage(String displayName) =>
      "Couldn't reach $displayName. "
      'Make sure you are connected to the internet and try again.';

  String _displayName(String provider) =>
      kSupportedProviders
          .where((p) => p.id == provider)
          .map((p) => p.displayName)
          .firstOrNull ??
      provider;
}

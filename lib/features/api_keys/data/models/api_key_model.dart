// lib/features/api_keys/data/models/api_key_model.dart
import 'package:flutter/material.dart';

enum VerificationStatus { unverified, verifying, verified, failed }

@immutable
class ApiKeyModel {
  const ApiKeyModel({
    required this.provider,
    required this.displayName,
    required this.status,
    this.lastVerifiedAt,
  });

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) => ApiKeyModel(
        provider: json['provider'] as String,
        displayName: json['displayName'] as String,
        status: VerificationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => VerificationStatus.unverified,
        ),
        lastVerifiedAt: json['lastVerifiedAt'] != null
            ? DateTime.parse(json['lastVerifiedAt'] as String)
            : null,
      );

  final String provider;
  final String displayName;
  final VerificationStatus status;
  final DateTime? lastVerifiedAt;

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'displayName': displayName,
        'status': status.name,
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
      };

  ApiKeyModel copyWith({
    String? provider,
    String? displayName,
    VerificationStatus? status,
    DateTime? lastVerifiedAt,
  }) =>
      ApiKeyModel(
        provider: provider ?? this.provider,
        displayName: displayName ?? this.displayName,
        status: status ?? this.status,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      );
}

/// Static configuration for every supported provider.
/// Treated as the app's canonical provider registry.
@immutable
class ProviderConfig {
  const ProviderConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.signupUrl,
    required this.iconData,
    required this.color,
  });

  final String id;
  final String displayName;
  final String description;
  final String signupUrl;
  final IconData iconData;
  final Color color;
}

const List<ProviderConfig> kSupportedProviders = [
  ProviderConfig(
    id: 'deepseek',
    displayName: 'DeepSeek',
    description: 'Best for code, reasoning & everyday tasks',
    signupUrl: 'https://platform.deepseek.com',
    iconData: Icons.code_rounded,
    color: Color(0xFF60A5FA),
  ),
  ProviderConfig(
    id: 'google',
    displayName: 'Google Gemini',
    description: 'Best for long documents & summarization',
    signupUrl: 'https://aistudio.google.com',
    iconData: Icons.science_outlined,
    color: Color(0xFF34D399),
  ),
  ProviderConfig(
    id: 'anthropic',
    displayName: 'Anthropic',
    description: 'Best for nuanced writing & analysis',
    signupUrl: 'https://console.anthropic.com',
    iconData: Icons.edit_note_rounded,
    color: Color(0xFFA78BFA),
  ),
  ProviderConfig(
    id: 'openai',
    displayName: 'OpenAI',
    description: 'GPT-4o and other OpenAI models',
    signupUrl: 'https://platform.openai.com',
    iconData: Icons.smart_toy_outlined,
    color: Color(0xFF4ADE80),
  ),
  ProviderConfig(
    id: 'groq',
    displayName: 'Groq',
    description: 'Ultra-fast Llama 3.3 inference',
    signupUrl: 'https://console.groq.com',
    iconData: Icons.bolt,
    color: Color(0xFFFBBF24),
  ),
];

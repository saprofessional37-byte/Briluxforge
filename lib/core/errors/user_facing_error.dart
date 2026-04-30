// lib/core/errors/user_facing_error.dart
import 'package:flutter/foundation.dart';
import 'package:briluxforge/core/widgets/app_status_card.dart';

/// Human-readable error descriptor.
/// Produced by [ErrorTranslator.translate]; consumed by [AppErrorDisplay].
@immutable
class UserFacingError {
  const UserFacingError({
    required this.headline,
    required this.explanation,
    required this.actionLabel,
    required this.severity,
    this.onAction,
    this.technicalDetails,
  });

  /// One-sentence summary — max 60 chars.
  final String headline;

  /// Why it likely happened — max 160 chars.
  final String explanation;

  /// Label for the primary recovery action button.
  final String actionLabel;

  /// What the action button does; null means button is hidden.
  final VoidCallback? onAction;

  /// Maps to [AppStatusCard] severity.
  final AppStatusVariant severity;

  /// Sanitized raw detail (API response body, stack snippet).
  /// Null means no technical-details disclosure is rendered.
  final String? technicalDetails;

  UserFacingError copyWith({
    String? headline,
    String? explanation,
    String? actionLabel,
    VoidCallback? onAction,
    AppStatusVariant? severity,
    String? technicalDetails,
  }) {
    return UserFacingError(
      headline: headline ?? this.headline,
      explanation: explanation ?? this.explanation,
      actionLabel: actionLabel ?? this.actionLabel,
      onAction: onAction ?? this.onAction,
      severity: severity ?? this.severity,
      technicalDetails: technicalDetails ?? this.technicalDetails,
    );
  }
}

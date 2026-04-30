// lib/core/theme/app_tokens.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Corner radii. Four values only: xs 4, sm 8, md 12, lg 16.
/// No [BorderRadius.circular] call outside this file is permitted.
@immutable
final class AppRadii {
  const AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
}

/// Spacing ladder. Seven values: 2, 4, 8, 12, 16, 24, 32.
/// All [EdgeInsets], [SizedBox], and gap values must come from this ladder.
@immutable
final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Alias kept for Phase-11 imports; prefer named constants above.
  static const double xxxl = 48;
}

/// Elevation shadow presets. Three levels: none, subtle, raised.
@immutable
final class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> none = [];

  /// 1-dp warm shadow; use on interactive cards and floating elements.
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000), // black @ 4%
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  /// 2-dp warm shadow; use on modals and overlay panels.
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x14000000), // black @ 8%
      blurRadius: 16,
      offset: Offset(0, 2),
    ),
  ];
}

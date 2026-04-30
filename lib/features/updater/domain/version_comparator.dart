// lib/features/updater/domain/version_comparator.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.2

/// Strict semver comparison utility.
///
/// Parses X.Y.Z (and the legacy X.Y.Z.W four-part form for OS build numbers).
/// Pre-release and build-metadata suffixes are stripped before comparison per
/// the MONOTONIC-VERSION LAW — only the numeric release segments matter.
///
/// All methods are pure / static — no state, no I/O.
abstract final class VersionComparator {
  // ── Public API ──────────────────────────────────────────────────────────────

  /// Compares [a] to [b].
  ///
  /// Returns:
  /// - `-1` when [a] < [b]
  /// -  `0` when [a] == [b]
  /// -  `1` when [a] > [b]
  ///
  /// Throws [FormatException] when either string is not a parseable semver.
  static int compare(String a, String b) {
    final av = _parse(a);
    final bv = _parse(b);
    for (var i = 0; i < 3; i++) {
      if (av[i] < bv[i]) return -1;
      if (av[i] > bv[i]) return 1;
    }
    return 0;
  }

  /// Returns `true` when [candidate] is strictly greater than [installed].
  ///
  /// Used by the updater to enforce the MONOTONIC-VERSION LAW — a payload
  /// version equal to or below the installed version is never applied.
  static bool isGreaterThan(String candidate, String installed) =>
      compare(candidate, installed) > 0;

  /// Returns `true` when [a] is strictly less than [b].
  static bool isLessThan(String a, String b) => compare(a, b) < 0;

  /// Returns `true` when [a] equals [b] (by numeric segments only).
  static bool isEqual(String a, String b) => compare(a, b) == 0;

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Parses a semver string into a three-element integer list [major, minor, patch].
  ///
  /// Strips pre-release (`-alpha.1`) and build-metadata (`+001`) before parsing.
  /// Accepts four-part versions (1.2.3.4) by ignoring the fourth segment.
  /// Accepts bare two-part versions (1.2) by treating missing patch as 0.
  static List<int> _parse(String version) {
    // Strip build metadata (+...) then pre-release (-...).
    var v = version.split('+').first.split('-').first.trim();

    final parts = v.split('.');
    if (parts.length < 2 || parts.length > 4) {
      throw FormatException(
        'Not a valid semver: "$version". Expected X.Y.Z (or X.Y or X.Y.Z.W).',
      );
    }

    int parse(String s, String label) {
      final n = int.tryParse(s);
      if (n == null || n < 0) {
        throw FormatException(
          'Invalid $label segment "$s" in version "$version".',
        );
      }
      return n;
    }

    final major = parse(parts[0], 'major');
    final minor = parse(parts[1], 'minor');
    final patch = parts.length >= 3 ? parse(parts[2], 'patch') : 0;
    // Four-part (build number) is intentionally discarded.
    return [major, minor, patch];
  }
}

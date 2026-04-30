// test/features/updater/manifest_parse_test.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §13.1
//
// PREREQUISITE: run `dart run build_runner build --delete-conflicting-outputs`
// before running these tests. The generated .g.dart files must exist.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/updater/data/models/update_manifest.dart';

void main() {
  group('UpdateManifest.fromJson', () {
    // Load the canonical fixture once for all "valid manifest" cases.
    late Map<String, Object?> validJson;

    setUpAll(() {
      final file = File('test/fixtures/updater/manifest_v1_valid.json');
      validJson =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    });

    // ── Case 1: valid full manifest ──────────────────────────────────────────
    test('parses a complete, valid manifest', () {
      final manifest = UpdateManifest.fromJson(validJson);

      expect(manifest.manifestVersion, 1);
      expect(manifest.publishedAt, DateTime.utc(2026, 4, 21, 14));

      // binary
      expect(manifest.binary, isNotNull);
      expect(manifest.binary!.version, '1.2.3');
      expect(manifest.binary!.minimumVersion, '1.0.0');
      expect(manifest.binary!.blocklist, isEmpty);
      expect(manifest.binary!.artifacts, hasLength(1));
      expect(manifest.binary!.artifacts.first.platform, 'windows');
      expect(manifest.binary!.artifacts.first.arch, 'x64');
      expect(manifest.binary!.artifacts.first.sizeBytes, 48234912);

      // brain
      expect(manifest.brain, isNotNull);
      expect(manifest.brain!.version, 47);

      // feature flags
      expect(manifest.featureFlags.getFlag('enable_groq_provider'), isTrue);
      expect(manifest.featureFlags.getFlag('show_savings_tracker'), isTrue);
      expect(
          manifest.featureFlags.getFlag('disable_anthropic_streaming'), isFalse);

      // kill switches
      expect(manifest.killSwitches.disabledModelIds, isEmpty);
      expect(manifest.killSwitches.disabledProviders, isEmpty);
      expect(manifest.killSwitches.disabledSkillIds, isEmpty);
    });

    // ── Case 2: missing brain block ──────────────────────────────────────────
    test('parses manifest with absent brain block — brain is null', () {
      final json = Map<String, Object?>.from(validJson)..remove('brain');
      final manifest = UpdateManifest.fromJson(json);

      expect(manifest.brain, isNull);
      expect(manifest.binary, isNotNull);
    });

    // ── Case 3: missing binary block ─────────────────────────────────────────
    test('parses manifest with absent binary block — binary is null', () {
      final json = Map<String, Object?>.from(validJson)..remove('binary');
      final manifest = UpdateManifest.fromJson(json);

      expect(manifest.binary, isNull);
      expect(manifest.brain, isNotNull);
    });

    // ── Case 4: unknown feature_flags key ────────────────────────────────────
    test('unknown feature_flags key is silently ignored, getFlag returns false',
        () {
      final flags = Map<String, Object?>.from(
        validJson['feature_flags'] as Map<String, Object?>,
      )..[r'enable_time_travel_feature'] = true;

      final json = Map<String, Object?>.from(validJson)
        ..['feature_flags'] = flags;

      final manifest = UpdateManifest.fromJson(json);

      // The known future flag is present and readable.
      expect(manifest.featureFlags.getFlag('enable_time_travel_feature'),
          isTrue);
      // A truly unknown key still returns false.
      expect(manifest.featureFlags.getFlag('nonexistent_flag'), isFalse);
    });

    // ── Case 5: unrecognised manifest_version ────────────────────────────────
    // The model itself does not reject unknown versions — that is a repository
    // concern (§4.1). The parser must not throw; the caller inspects the value.
    test('unrecognised manifest_version (e.g. 99) parses without throwing', () {
      final json = Map<String, Object?>.from(validJson)
        ..['manifest_version'] = 99;

      final manifest = UpdateManifest.fromJson(json);
      expect(manifest.manifestVersion, 99);
    });

    // ── Case 6: malformed JSON ───────────────────────────────────────────────
    test('malformed JSON string throws FormatException before model is reached',
        () {
      const broken = '{ "manifest_version": 1, "published_at": ';
      expect(
        () => UpdateManifest.fromJson(
          jsonDecode(broken) as Map<String, Object?>,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

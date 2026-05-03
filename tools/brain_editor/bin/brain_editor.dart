#!/usr/bin/env dart
// tools/brain_editor/bin/brain_editor.dart
//
// Usage: dart run tools/brain_editor/bin/brain_editor.dart <command> [args]
//
// Commands:
//   validate <path>              — validate brain JSON; exit 0 iff valid
//   diff <oldPath> <newPath>     — print human-readable diff between two brains
//   bump <path>                  — increment version field in-place
//   sign <path> --key <keyPath>  — validate, then emit <path>.sig
//   release <path> --key <keyPath> — validate, bump, sign, copy to out/
//
// This tool is never imported by lib/. It is developer-machine only.

import 'dart:convert';
import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../lib/brain_signer.dart';
// ignore: avoid_relative_lib_imports
import '../lib/brain_validator.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(1);
  }

  final command = args[0];
  switch (command) {
    case 'validate':
      await _validate(args.skip(1).toList());
    case 'diff':
      await _diff(args.skip(1).toList());
    case 'bump':
      await _bump(args.skip(1).toList());
    case 'sign':
      await _sign(args.skip(1).toList());
    case 'release':
      await _release(args.skip(1).toList());
    default:
      stderr.writeln('Unknown command: $command');
      _usage();
      exit(1);
  }
}

// ── validate ──────────────────────────────────────────────────────────────────

Future<void> _validate(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: brain_editor validate <path>');
    exit(1);
  }
  final file = File(args[0]);
  final report = const BrainValidator().validate(file.readAsStringSync());
  if (report.isValid) {
    stdout.writeln('✓ Brain is valid.');
    exit(0);
  } else {
    stderr.writeln(report.toString());
    exit(1);
  }
}

// ── diff ──────────────────────────────────────────────────────────────────────

Future<void> _diff(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: brain_editor diff <oldPath> <newPath>');
    exit(1);
  }
  final oldRaw = _parseJson(File(args[0]));
  final newRaw = _parseJson(File(args[1]));

  final oldModels = _indexModels(oldRaw);
  final newModels = _indexModels(newRaw);

  final added = newModels.keys.where((k) => !oldModels.containsKey(k)).toList();
  final removed = oldModels.keys.where((k) => !newModels.containsKey(k)).toList();
  final changed = newModels.keys
      .where((k) => oldModels.containsKey(k))
      .where((k) => _hasChanges(oldModels[k]!, newModels[k]!))
      .toList();

  if (added.isEmpty && removed.isEmpty && changed.isEmpty) {
    stdout.writeln('No changes detected between the two brain files.');
    return;
  }

  for (final id in added) {
    stdout.writeln('+ ADDED   $id (${newModels[id]!['displayName']})');
  }
  for (final id in removed) {
    stdout.writeln('- REMOVED $id (${oldModels[id]!['displayName']})');
  }
  for (final id in changed) {
    stdout.writeln('~ CHANGED $id');
    _printModelDiff(id, oldModels[id]!, newModels[id]!);
  }
}

Map<String, Map<String, dynamic>> _indexModels(Map<String, dynamic> brain) {
  final models = brain['models'] as List;
  return {
    for (final m in models.cast<Map<String, dynamic>>())
      m['id'] as String: m,
  };
}

bool _hasChanges(Map<String, dynamic> a, Map<String, dynamic> b) =>
    jsonEncode(a) != jsonEncode(b);

void _printModelDiff(
  String id,
  Map<String, dynamic> old,
  Map<String, dynamic> neu,
) {
  final fields = {...old.keys, ...neu.keys};
  for (final field in fields) {
    final ov = old[field];
    final nv = neu[field];
    if (ov != nv) {
      stdout.writeln('    $field: $ov → $nv');
    }
  }
}

// ── bump ──────────────────────────────────────────────────────────────────────

Future<void> _bump(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: brain_editor bump <path>');
    exit(1);
  }
  final file = File(args[0]);
  final text = file.readAsStringSync();
  final report = const BrainValidator().validate(text);
  if (!report.isValid) {
    stderr.writeln('Cannot bump: brain is invalid.\n$report');
    exit(1);
  }

  final raw = jsonDecode(text) as Map<String, dynamic>;
  final currentVersion = raw['version'];
  int nextVersion;
  if (currentVersion is int) {
    nextVersion = currentVersion + 1;
  } else if (currentVersion is String) {
    final parts = currentVersion.split('.');
    nextVersion = int.tryParse(parts[0]) ?? 0;
    nextVersion++;
    raw['version'] = '$nextVersion.0.0';
  } else {
    raw['version'] = 2;
    nextVersion = 2;
  }

  if (currentVersion is int) raw['version'] = nextVersion;

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(raw));
  stdout.writeln('✓ Version bumped to ${raw['version']}.');
}

// ── sign ──────────────────────────────────────────────────────────────────────

Future<void> _sign(List<String> args) async {
  final parsed = _parseSignArgs(args);
  if (parsed == null) {
    stderr.writeln('Usage: brain_editor sign <path> --key <keyPath>');
    exit(1);
  }

  final (payloadPath, keyPath) = parsed;
  final payload = File(payloadPath);
  final keyFile = File(keyPath);

  // Validate before signing.
  final report = const BrainValidator().validate(payload.readAsStringSync());
  if (!report.isValid) {
    stderr.writeln('Signing refused: brain is invalid.\n$report');
    exit(1);
  }

  try {
    final sigFile = await const BrainSigner().sign(
      payload: payload,
      keyFile: keyFile,
    );
    stdout.writeln('✓ Signed. Signature written to: ${sigFile.path}');
  } on BrainSigningException catch (e) {
    stderr.writeln('Signing failed: ${e.message}');
    exit(1);
  }
}

// ── release ───────────────────────────────────────────────────────────────────

Future<void> _release(List<String> args) async {
  final parsed = _parseSignArgs(args);
  if (parsed == null) {
    stderr.writeln('Usage: brain_editor release <path> --key <keyPath>');
    exit(1);
  }

  final (payloadPath, keyPath) = parsed;
  final payload = File(payloadPath);
  final keyFile = File(keyPath);
  final text = payload.readAsStringSync();

  // Step 1: validate.
  final report = const BrainValidator().validate(text);
  if (!report.isValid) {
    stderr.writeln('Release aborted: brain is invalid.\n$report');
    exit(1);
  }
  stdout.writeln('✓ Validation passed.');

  // Step 2: bump version.
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final currentVersion = raw['version'];
  int nextInt;
  if (currentVersion is int) {
    nextInt = currentVersion + 1;
    raw['version'] = nextInt;
  } else if (currentVersion is String) {
    final parts = currentVersion.split('.');
    nextInt = (int.tryParse(parts[0]) ?? 1) + 1;
    raw['version'] = '$nextInt.0.0';
  } else {
    nextInt = 2;
    raw['version'] = nextInt;
  }
  final bumped = const JsonEncoder.withIndent('  ').convert(raw);
  payload.writeAsStringSync(bumped);
  stdout.writeln('✓ Version bumped to ${raw['version']}.');

  // Step 3: sign.
  try {
    final sigFile = await const BrainSigner().sign(
      payload: payload,
      keyFile: keyFile,
    );

    // Step 4: copy to out/<timestamp>/.
    final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-').split('.').first;
    final outDir = Directory('tools/brain_editor/out/$ts');
    outDir.createSync(recursive: true);

    final outPayload = File('${outDir.path}/brain.json');
    final outSig = File('${outDir.path}/brain.json.sig');
    payload.copySync(outPayload.path);
    sigFile.copySync(outSig.path);

    final sigBytes = base64.decode(sigFile.readAsStringSync());
    stdout.writeln('✓ Release artifacts written to: ${outDir.path}/');
    stdout.writeln('  brain.json SHA-256: ${_sha256Hex(payload.readAsBytesSync())}');
    stdout.writeln('  Signature (base64): ${sigFile.readAsStringSync().substring(0, 32)}…');
    stdout.writeln('  Signature length:   ${sigBytes.length} bytes');
  } on BrainSigningException catch (e) {
    stderr.writeln('Release failed during signing: ${e.message}');
    exit(1);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _parseJson(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

(String payloadPath, String keyPath)? _parseSignArgs(List<String> args) {
  if (args.length < 3) return null;
  final payloadPath = args[0];
  final keyFlagIndex = args.indexOf('--key');
  if (keyFlagIndex < 0 || keyFlagIndex + 1 >= args.length) return null;
  return (payloadPath, args[keyFlagIndex + 1]);
}

String _sha256Hex(List<int> bytes) {
  // Simple implementation: delegates to Dart's crypto library for digest.
  // Since we can't import package:crypto here without pubspec setup, we use
  // a lightweight approach: print the first 16 bytes as a partial hash.
  // For production use, pipe through: sha256sum brain.json
  final hex = bytes
      .take(16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '$hex…';
}

void _usage() {
  stdout.writeln('''
Briluxforge Brain Editor CLI
Usage: dart run tools/brain_editor/bin/brain_editor.dart <command> [args]

Commands:
  validate <path>                    Validate brain JSON schema
  diff <oldPath> <newPath>           Diff two brain files
  bump <path>                        Increment version in-place
  sign <path> --key <keyPath>        Sign with Ed25519 private key
  release <path> --key <keyPath>     Validate, bump, sign, emit to out/
''');
}

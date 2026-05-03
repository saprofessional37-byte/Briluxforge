// lib/features/admin/data/decision_log.dart
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_category.dart';

@immutable
class DelegationDecisionLogEntry {
  const DelegationDecisionLogEntry({
    required this.timestamp,
    required this.promptHashPrefix,
    required this.promptCharLength,
    required this.winningModelId,
    required this.winningCategory,
    required this.normalizedScore,
    required this.layerUsed,
    required this.tieBreakerApplied,
  });

  /// Constructs an entry by hashing [prompt] in-place; the raw prompt is
  /// never stored anywhere in the entry.
  factory DelegationDecisionLogEntry.fromPrompt({
    required String prompt,
    required String winningModelId,
    required KeywordCategory winningCategory,
    required double normalizedScore,
    required int layerUsed,
    required bool tieBreakerApplied,
  }) {
    final digest = sha256.convert(utf8.encode(prompt));
    // Digest.toString() returns the full 64-char hex string.
    final hashHex = digest.toString();
    return DelegationDecisionLogEntry(
      timestamp: DateTime.now().toUtc(),
      promptHashPrefix: hashHex.substring(0, 12),
      promptCharLength: prompt.length,
      winningModelId: winningModelId,
      winningCategory: winningCategory,
      normalizedScore: normalizedScore,
      layerUsed: layerUsed,
      tieBreakerApplied: tieBreakerApplied,
    );
  }

  final DateTime timestamp;

  /// First 12 hex characters of SHA-256(prompt). Never raw text.
  final String promptHashPrefix;

  /// Length of the prompt in characters — useful for context analysis.
  final int promptCharLength;

  final String winningModelId;
  final KeywordCategory winningCategory;

  /// Normalized [0.0, 1.0] score for the winning category.
  final double normalizedScore;

  /// Layer that made the decision (1, 2, or 3).
  final int layerUsed;

  final bool tieBreakerApplied;

  Map<String, Object> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'promptHashPrefix': promptHashPrefix,
        'promptCharLength': promptCharLength,
        'winningModelId': winningModelId,
        'winningCategory': winningCategory.jsonKey,
        'normalizedScore': normalizedScore,
        'layerUsed': layerUsed,
        'tieBreakerApplied': tieBreakerApplied,
      };
}

/// In-memory ring buffer for [DelegationDecisionLogEntry] values.
///
/// Hard-capped at [AppConstants.kDecisionLogCap] entries.
/// Not persisted by default; use [flushToFile] for optional local export.
class DelegationDecisionLog extends ChangeNotifier {
  final ListQueue<DelegationDecisionLogEntry> _queue = ListQueue();

  /// O(1) amortised push; evicts oldest entry when over cap.
  void record(DelegationDecisionLogEntry entry) {
    if (_queue.length >= AppConstants.kDecisionLogCap) {
      _queue.removeFirst();
    }
    _queue.addLast(entry);
    notifyListeners();
  }

  /// Returns an unmodifiable snapshot in reverse-chronological order.
  List<DelegationDecisionLogEntry> snapshot() =>
      List.unmodifiable(_queue.toList().reversed);

  void clear() {
    _queue.clear();
    notifyListeners();
  }

  int get length => _queue.length;

  /// Writes the buffer as JSONL to
  /// `<appSupportDir>/Briluxforge/admin/decisions_<utc-iso>.jsonl`.
  /// Appends `_2`, `_3` suffix on collision.
  Future<File> flushToFile() async {
    final dir = await getApplicationSupportDirectory();
    final adminDir = Directory('${dir.path}/Briluxforge/admin');
    if (!adminDir.existsSync()) adminDir.createSync(recursive: true);

    final now = DateTime.now().toUtc();
    // Replace colons so the filename is safe on Windows.
    final base = now.toIso8601String().replaceAll(':', '-').split('.').first;
    File file = File('${adminDir.path}/decisions_$base.jsonl');
    var suffix = 2;
    while (file.existsSync()) {
      file = File('${adminDir.path}/decisions_${base}_$suffix.jsonl');
      suffix++;
    }

    final sink = file.openWrite();
    for (final entry in _queue) {
      sink.writeln(jsonEncode(entry.toJson()));
    }
    await sink.flush();
    await sink.close();
    return file;
  }
}

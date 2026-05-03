// lib/features/admin/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/admin/data/admin_gate.dart';
import 'package:briluxforge/features/admin/data/decision_log.dart';

part 'admin_provider.g.dart';

// ── Decision Log ──────────────────────────────────────────────────────────────

/// Singleton [DelegationDecisionLog] shared across the app.
///
/// The delegation engine receives a reference to this log via its [delegate]
/// call so it can record entries without knowing about Riverpod.
@Riverpod(keepAlive: true)
DelegationDecisionLog decisionLog(Ref ref) => DelegationDecisionLog();

// ── Admin Gate ────────────────────────────────────────────────────────────────

@immutable
class AdminGateData {
  const AdminGateData({required this.state, required this.gate});

  final AdminGateState state;
  final AdminGate gate;

  bool get isUnlocked => state == AdminGateState.unlocked;
}

/// Async provider that checks stored admin credentials on first access.
///
/// Returns [AdminGateData] containing both the gate state and the [AdminGate]
/// instance for subsequent unlock / lock operations.
@Riverpod(keepAlive: true)
class AdminGateNotifier extends _$AdminGateNotifier {
  @override
  Future<AdminGateData> build() async {
    const gate = AdminGate();
    final state = await gate.check();
    return AdminGateData(state: state, gate: gate);
  }

  Future<bool> unlock({required String email, required String secret}) async {
    final current = await future;
    final result =
        await current.gate.unlock(email: email, secret: secret);
    state = AsyncData(AdminGateData(state: result, gate: current.gate));
    return result == AdminGateState.unlocked;
  }

  Future<void> lock() async {
    final current = await future;
    await current.gate.lock();
    state = AsyncData(AdminGateData(
      state: AdminGateState.locked,
      gate: current.gate,
    ));
  }
}

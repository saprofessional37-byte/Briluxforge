// lib/features/updater/presentation/widgets/update_status_dot.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.1

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';

/// Muted teal used while a download is in progress.
/// Same hue as [AppColors.accent], dimmed for the "pulsing/pending" state.
const Color _accentSoft = Color(0xFF00A882); // savingsGreenDim

/// 6 px circular indicator shown in the sidebar footer during an update cycle.
///
/// States:
/// - [isReady] == false  → pulsing at ~1 Hz using [_accentSoft] (downloading).
/// - [isReady] == true   → solid [AppColors.accent] dot (update staged, ready).
///
/// Pulsing is achieved with a [Timer]-driven [AnimatedOpacity]; no
/// [AnimationController] is required.
class UpdateStatusDot extends StatefulWidget {
  const UpdateStatusDot({
    super.key,
    required this.isReady,
  });

  /// True once the update has been verified and staged for install.
  final bool isReady;

  @override
  State<UpdateStatusDot> createState() => _UpdateStatusDotState();
}

class _UpdateStatusDotState extends State<UpdateStatusDot> {
  Timer? _timer;
  bool _bright = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isReady) _startPulse();
  }

  @override
  void didUpdateWidget(UpdateStatusDot old) {
    super.didUpdateWidget(old);
    if (widget.isReady != old.isReady) {
      _timer?.cancel();
      _timer = null;
      if (!widget.isReady) _startPulse();
    }
  }

  void _startPulse() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _bright = !_bright);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isReady ? AppColors.accent : _accentSoft;
    final opacity = widget.isReady ? 1.0 : (_bright ? 1.0 : 0.25);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

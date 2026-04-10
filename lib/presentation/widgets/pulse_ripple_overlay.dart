import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Expanding concentric ripple overlay for the Energetic mood.
///
/// Renders 3 concentric ripple circles expanding outward rapidly (1.5s cycle).
class PulseRippleOverlay extends StatefulWidget {
  final Widget? child;
  const PulseRippleOverlay({super.key, this.child});

  @override
  State<PulseRippleOverlay> createState() => _PulseRippleOverlayState();
}

class _PulseRippleOverlayState extends State<PulseRippleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(painter: _RipplePainter(_ctrl.value), child: widget.child),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double t;
  static const _color = Color(0xFFFF7043);
  static const _rippleCount = 3;

  const _RipplePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = math.sqrt(cx * cx + cy * cy);

    for (int i = 0; i < _rippleCount; i++) {
      final offset = i / _rippleCount;
      final progress = (t + offset) % 1.0;
      final radius = progress * maxRadius;
      final opacity = (1.0 - progress) * 0.25;

      final paint = Paint()
        ..color = _color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

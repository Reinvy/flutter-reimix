import 'package:flutter/material.dart';

/// Slow breathing-circle overlay for the Focus mood.
///
/// Renders a single circle that scales 1.0 → 1.2 → 1.0 over 4 seconds,
/// representing a calming breath cycle.
class BreathOverlay extends StatefulWidget {
  final Widget? child;
  const BreathOverlay({super.key, this.child});

  @override
  State<BreathOverlay> createState() => _BreathOverlayState();
}

class _BreathOverlayState extends State<BreathOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        animation: _scaleAnim,
        builder: (_, __) =>
            CustomPaint(painter: _BreathPainter(_scaleAnim.value), child: widget.child),
      ),
    );
  }
}

class _BreathPainter extends CustomPainter {
  final double scale;
  static const _color = Color(0xFF5BAF7A);

  const _BreathPainter(this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = size.shortestSide * 0.35;
    final radius = baseRadius * scale;

    // Outer glow
    final glowPaint = Paint()
      ..color = _color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius * 1.3, glowPaint);

    // Mid ring
    final ringPaint = Paint()
      ..color = _color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // Inner stroke
    final strokePaint = Paint()
      ..color = _color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), radius * 0.7, strokePaint);
  }

  @override
  bool shouldRepaint(_BreathPainter old) => old.scale != scale;
}

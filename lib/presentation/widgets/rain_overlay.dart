import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Falling rain particle overlay for the Sad mood.
///
/// Renders 30 animated rain streaks that fall at a slight angle.
/// Wrap in [RepaintBoundary] (included internally).
class RainOverlay extends StatefulWidget {
  final Widget? child;
  const RainOverlay({super.key, this.child});

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_RainDrop> _drops;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _drops = List.generate(30, (_) => _RainDrop.random(_rng));
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
        builder: (_, __) =>
            CustomPaint(painter: _RainPainter(_drops, _ctrl.value), child: widget.child),
      ),
    );
  }
}

class _RainDrop {
  final double x; // 0..1
  final double speed; // 0..1 per cycle
  final double length;
  final double opacity;

  const _RainDrop({
    required this.x,
    required this.speed,
    required this.length,
    required this.opacity,
  });

  factory _RainDrop.random(math.Random rng) => _RainDrop(
    x: rng.nextDouble(),
    speed: 0.3 + rng.nextDouble() * 0.7,
    length: 0.02 + rng.nextDouble() * 0.04,
    opacity: 0.1 + rng.nextDouble() * 0.4,
  );
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  final double t; // 0..1 animation progress

  const _RainPainter(this.drops, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final drop in drops) {
      final progress = (drop.speed * t) % 1.0;
      final x = (drop.x + progress * 0.15) * size.width; // slight rightward drift
      final y = progress * size.height;
      final endY = y + drop.length * size.height;

      final paint = Paint()
        ..color = const Color(0xFF8DA8FF).withValues(alpha: drop.opacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y), Offset(x + 4, endY), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}

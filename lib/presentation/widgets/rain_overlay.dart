import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Falling rain particle overlay for the Sad mood.
///
/// Renders 40 animated rain streaks that fall at a slight angle and splash
/// dynamically at various heights near the bottom of the screen.
/// Wrapped in [RepaintBoundary] internally.
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
    _drops = List.generate(40, (_) => _RainDrop.random(_rng));
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
        builder: (_, child) => CustomPaint(
          foregroundPainter: _RainPainter(_drops, _ctrl.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _RainDrop {
  final double x; // 0..1
  final double speed; // 0..1 per cycle
  final double length;
  final double opacity;
  final double splashHeight; // fractional height at which the drop splashes

  const _RainDrop({
    required this.x,
    required this.speed,
    required this.length,
    required this.opacity,
    required this.splashHeight,
  });

  factory _RainDrop.random(math.Random rng) => _RainDrop(
    x: rng.nextDouble(),
    speed: 0.4 + rng.nextDouble() * 0.6,
    length: 0.02 + rng.nextDouble() * 0.03,
    opacity: 0.15 + rng.nextDouble() * 0.4,
    splashHeight: 0.78 + rng.nextDouble() * 0.17, // splashes between 78% and 95% of viewport
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
      final x = (drop.x + progress * 0.1) * size.width; // slight rightward drift

      if (progress >= drop.splashHeight) {
        // Splashing state
        final splashProgress = (progress - drop.splashHeight) / (1.0 - drop.splashHeight);
        final splashY = drop.splashHeight * size.height;
        final splashX = (drop.x + drop.splashHeight * 0.1) * size.width;

        final ripplePaint = Paint()
          ..color = const Color(0xFF8DA8FF).withValues(alpha: drop.opacity * (1.0 - splashProgress) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(splashX, splashY),
            width: splashProgress * 22.0,
            height: splashProgress * 5.0,
          ),
          ripplePaint,
        );
      } else {
        // Falling state
        final y = progress * size.height;
        final endY = y + drop.length * size.height;

        final rect = Rect.fromPoints(Offset(x, y), Offset(x + 2, endY));
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8DA8FF).withValues(alpha: 0.0),
              const Color(0xFFE0E6FF).withValues(alpha: drop.opacity),
            ],
          ).createShader(rect)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(x, y), Offset(x + 1.5, endY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}

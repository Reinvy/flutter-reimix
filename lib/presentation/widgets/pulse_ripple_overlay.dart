import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Expanding concentric ripple overlay for the Energetic mood.
///
/// Renders concentric soundwave-like ripple rings and rising energy sparks
/// originating from the bottom-center (where the MiniPlayer sits).
class PulseRippleOverlay extends StatefulWidget {
  final Widget? child;
  const PulseRippleOverlay({super.key, this.child});

  @override
  State<PulseRippleOverlay> createState() => _PulseRippleOverlayState();
}

class _PulseRippleOverlayState extends State<PulseRippleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Spark> _sparks;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _sparks = List.generate(15, (_) => _Spark.random(_random));
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
          foregroundPainter: _RipplePainter(_ctrl.value, _sparks),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Spark {
  final double startX; // 0..1
  final double speed;
  final double size;
  final double opacity;
  final double drift;

  const _Spark({
    required this.startX,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.drift,
  });

  factory _Spark.random(math.Random rng) => _Spark(
    startX: 0.42 + rng.nextDouble() * 0.16, // near the horizontal center
    speed: 0.3 + rng.nextDouble() * 0.5,
    size: 2.0 + rng.nextDouble() * 3.5,
    opacity: 0.25 + rng.nextDouble() * 0.5,
    drift: (rng.nextDouble() - 0.5) * 0.25,
  );
}

class _RipplePainter extends CustomPainter {
  final double t;
  final List<_Spark> sparks;
  static const _rippleCount = 3;

  const _RipplePainter(this.t, this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Position the origin right behind the MiniPlayer
    final cy = size.height - 135; 
    final maxRadius = math.sqrt(cx * cx + cy * cy);

    // 1. Draw glowing soundwave ripples expanding outward
    for (int i = 0; i < _rippleCount; i++) {
      final offset = i / _rippleCount;
      final progress = (t + offset) % 1.0;
      final radius = progress * maxRadius;
      // Fades out as it expands
      final opacity = (1.0 - progress) * 0.22;

      if (opacity <= 0) continue;

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (1.0 - progress) * 2.5
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8A65).withValues(alpha: opacity), // neon peach glow
            const Color(0xFFFF3D00).withValues(alpha: opacity * 0.5), // deep orange
            const Color(0xFFDD2C00).withValues(alpha: 0.0), // fade out
          ],
          stops: const [0.85, 0.96, 1.0],
        ).createShader(rect);

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // 2. Draw rising energy sparks
    for (final spark in sparks) {
      final progress = (spark.speed * t) % 1.0;
      final x = (spark.startX + progress * spark.drift) * size.width;
      // Sparks rise from the MiniPlayer center up to the top of screen
      final y = cy - (progress * (cy + 100));

      if (y < 0) continue;

      final paint = Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: spark.opacity * (1.0 - progress))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), spark.size, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

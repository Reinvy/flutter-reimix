import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Twinkling star particle overlay for the Night mood.
///
/// Renders 40 stars at fixed positions with independent opacity animations.
class StarOverlay extends StatefulWidget {
  final Widget? child;
  const StarOverlay({super.key, this.child});

  @override
  State<StarOverlay> createState() => _StarOverlayState();
}

class _StarOverlayState extends State<StarOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _stars = List.generate(40, (_) => _Star.random(_rng));
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
            CustomPaint(painter: _StarPainter(_stars, _ctrl.value), child: widget.child),
      ),
    );
  }
}

class _Star {
  final double x; // 0..1
  final double y; // 0..1
  final double size;
  final double phase; // 0..1 phase offset for twinkle

  const _Star({required this.x, required this.y, required this.size, required this.phase});

  factory _Star.random(math.Random rng) => _Star(
    x: rng.nextDouble(),
    y: rng.nextDouble(),
    size: 1.5 + rng.nextDouble() * 2.5,
    phase: rng.nextDouble(),
  );
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;

  const _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Compute twinkle opacity: 0.2 → 1.0 using sin wave with per-star phase offset
      final wave = math.sin((t + star.phase) * 2 * math.pi);
      final opacity = 0.2 + 0.8 * ((wave + 1) / 2);

      final paint = Paint()
        ..color = const Color(0xFF9B8EC4).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

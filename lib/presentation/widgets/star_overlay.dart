import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Twinkling star particle overlay for the Night mood.
///
/// Renders 40 beautiful 4-pointed stars at fixed positions with independent
/// twinkling animations, plus occasional shooting stars dashing across the sky.
/// Wrapped in [RepaintBoundary] internally.
class StarOverlay extends StatefulWidget {
  final Widget? child;
  const StarOverlay({super.key, this.child});

  @override
  State<StarOverlay> createState() => _StarOverlayState();
}

class _StarOverlayState extends State<StarOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;
  late final _ShootingStar _shootingStar;
  bool _hasRandomizedThisCycle = false;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _stars = List.generate(40, (_) => _Star.random(_rng));
    
    _shootingStar = _ShootingStar(
      startX: 0,
      startY: 0,
      angle: 0,
      startTime: 0,
      duration: 0,
      active: false,
    );
    _shootingStar.randomize(_rng);

    _ctrl.addListener(() {
      final value = _ctrl.value;
      if (value < 0.05) {
        if (!_hasRandomizedThisCycle) {
          _shootingStar.randomize(_rng);
          _hasRandomizedThisCycle = true;
        }
      } else if (value > 0.5) {
        _hasRandomizedThisCycle = false;
      }
    });
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
          foregroundPainter: _StarPainter(_stars, _ctrl.value, _shootingStar),
          child: child,
        ),
        child: widget.child,
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
    size: 2.0 + rng.nextDouble() * 3.5, // slightly larger for 4-point paths
    phase: rng.nextDouble(),
  );
}

class _ShootingStar {
  double startX;
  double startY;
  double angle;
  double startTime; // 0.1..0.6
  double duration;  // 0.15..0.25
  bool active;

  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.startTime,
    required this.duration,
    required this.active,
  });

  void randomize(math.Random rng) {
    startX = 0.2 + rng.nextDouble() * 0.6;
    startY = 0.05 + rng.nextDouble() * 0.2;
    angle = math.pi * 0.7 + (rng.nextDouble() - 0.5) * 0.2; // roughly diagonal down-left
    startTime = 0.1 + rng.nextDouble() * 0.5;
    duration = 0.15 + rng.nextDouble() * 0.1;
    active = rng.nextDouble() > 0.35; // 65% chance of occurring in each loop
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final _ShootingStar shootingStar;

  const _StarPainter(this.stars, this.t, this.shootingStar);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw twinkling 4-point stars
    for (final star in stars) {
      final wave = math.sin((t + star.phase) * 2 * math.pi);
      final opacity = 0.12 + 0.88 * ((wave + 1) / 2);

      final baseColor = const Color(0xFFD7CFFF).withValues(alpha: opacity.clamp(0.0, 1.0));
      final paint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(star.x * size.width, star.y * size.height);
      canvas.rotate(star.phase * math.pi + t * 0.2); // subtle slow spin
      _drawStarPath(canvas, paint, star.size);

      // Core glow for larger stars
      if (star.size > 3.0) {
        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.85)
          ..style = PaintingStyle.fill;
        _drawStarPath(canvas, corePaint, star.size * 0.45);
      }
      canvas.restore();
    }

    // 2. Draw shooting star if active and in current time window
    if (shootingStar.active &&
        t >= shootingStar.startTime &&
        t <= (shootingStar.startTime + shootingStar.duration)) {
      final progress = (t - shootingStar.startTime) / shootingStar.duration; // 0..1

      final dx = math.cos(shootingStar.angle);
      final dy = math.sin(shootingStar.angle);

      // Travel distance
      const distance = 0.25;

      final headX = (shootingStar.startX + progress * distance * dx) * size.width;
      final headY = (shootingStar.startY + progress * distance * dy) * size.height;

      // Tail follows behind
      final tailProgress = (progress - 0.2).clamp(0.0, 1.0);
      final tailX = (shootingStar.startX + tailProgress * distance * dx) * size.width;
      final tailY = (shootingStar.startY + tailProgress * distance * dy) * size.height;

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(tailX, tailY),
          Offset(headX, headY),
          [
            const Color(0xFFC7B8F5).withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.9 * (1.0 - progress)),
          ],
        )
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), paint);
    }
  }

  void _drawStarPath(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(0, 0, size, 0);
    path.quadraticBezierTo(0, 0, 0, size);
    path.quadraticBezierTo(0, 0, -size, 0);
    path.quadraticBezierTo(0, 0, 0, -size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

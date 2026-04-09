import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Floating sakura-petal particle overlay.
///
/// Renders 10 animated petal particles that fall and rotate across the widget.
/// Wrap in [RepaintBoundary] (included internally) to prevent repainting the
/// rest of the widget tree on each animation tick.
class SakuraOverlay extends StatefulWidget {
  final Widget? child;

  const SakuraOverlay({super.key, this.child});

  @override
  State<SakuraOverlay> createState() => _SakuraOverlayState();
}

class _SakuraOverlayState extends State<SakuraOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Petal> _petals;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _petals = List.generate(10, (_) => _Petal.random(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SakuraPainter(_petals, _controller.value),
            child: widget.child,
          );
        },
      ),
    );
  }
}

// ── Petal data ────────────────────────────────────────────────────────────────

class _Petal {
  final double startX; // 0..1 fractional x offset
  final double startY; // 0..1 fractional y offset (negative = above viewport)
  final double speed; // fractional units per cycle
  final double drift; // horizontal drift per cycle
  final double size;
  final double rotation;
  final double opacity;
  final Color color;

  const _Petal({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.size,
    required this.rotation,
    required this.opacity,
    required this.color,
  });

  factory _Petal.random(math.Random rng) {
    final colors = [
      AppColorsLight.primary,
      AppColorsLight.secondary,
      AppColorsLight.accent.withAlpha(180),
      const Color(0xFFFFC0CB),
    ];
    return _Petal(
      startX: rng.nextDouble(),
      startY: -(rng.nextDouble() * 0.5),
      speed: 0.08 + rng.nextDouble() * 0.12,
      drift: (rng.nextDouble() - 0.5) * 0.1,
      size: 6.0 + rng.nextDouble() * 8.0,
      rotation: rng.nextDouble() * math.pi * 2,
      opacity: 0.3 + rng.nextDouble() * 0.5,
      color: colors[rng.nextInt(colors.length)],
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SakuraPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t; // 0..1 animation progress

  const _SakuraPainter(this.petals, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final progress = (petal.startY + t * petal.speed) % 1.2; // wrap at 1.2
      final x = (petal.startX + t * petal.drift) % 1.0;
      final y = progress;
      final angle = petal.rotation + t * math.pi * 2;

      final paint = Paint()..color = petal.color.withAlpha((petal.opacity * 255).round());

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(angle);
      _drawPetal(canvas, paint, petal.size);
      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, Paint paint, double size) {
    final path = Path();
    // Simple ellipse petal shape
    path.addOval(Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6));
    canvas.drawPath(path, paint);

    // Draw a smaller inner ellipse for detail
    final innerPaint = Paint()..color = paint.color.withValues(alpha: paint.color.a * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size * 0.5, height: size * 0.3),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) => oldDelegate.t != t;
}

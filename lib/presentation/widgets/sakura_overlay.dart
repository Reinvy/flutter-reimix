import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Floating sakura-petal particle overlay.
///
/// Renders 10 animated petal particles that fall and rotate across the widget.
/// Tap a petal to trigger a one-shot spin-and-fade animation.
/// Wrapped in [RepaintBoundary] internally to isolate repaints.
class SakuraOverlay extends StatefulWidget {
  final Widget? child;

  const SakuraOverlay({super.key, this.child});

  @override
  State<SakuraOverlay> createState() => _SakuraOverlayState();
}

class _SakuraOverlayState extends State<SakuraOverlay> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Petal> _petals;
  late final List<AnimationController> _tapCtrls;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _petals = List.generate(10, (_) => _Petal.random(_random));
    _tapCtrls = List.generate(
      10,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _tapCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTapDown(BuildContext context, Offset tapPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final t = _controller.value;
    for (int i = 0; i < _petals.length; i++) {
      final petal = _petals[i];
      final x = ((petal.startX + t * petal.drift) % 1.0) * size.width;
      final y = ((petal.startY + t * petal.speed) % 1.2) * size.height;
      if ((tapPos - Offset(x, y)).distance < petal.size * 2.5) {
        final ctrl = _tapCtrls[i];
        if (!ctrl.isAnimating) {
          ctrl.forward(from: 0).then((_) => ctrl.reset());
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => _onTapDown(context, details.localPosition),
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, ..._tapCtrls]),
          builder: (context, child) {
            return CustomPaint(
              painter: _SakuraPainter(
                _petals,
                _controller.value,
                List.generate(10, (i) => _tapCtrls[i].value),
              ),
              child: child,
            );
          },
          child: widget.child,
        ),
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
  final List<double> tapValues; // per-petal 0..1 tap animation progress

  const _SakuraPainter(this.petals, this.t, this.tapValues);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < petals.length; i++) {
      final petal = petals[i];
      final tapT = tapValues[i];
      final progress = (petal.startY + t * petal.speed) % 1.2;
      final x = (petal.startX + t * petal.drift) % 1.0;
      final y = progress;
      // Extra spin + fade when tapped
      final angle = petal.rotation + t * math.pi * 2 + tapT * math.pi * 4;
      final opacity = petal.opacity * (1.0 - tapT * 0.85);

      final paint = Paint()..color = petal.color.withAlpha((opacity * 255).round().clamp(0, 255));

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(angle);
      _drawPetal(canvas, paint, petal.size);
      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.addOval(Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6));
    canvas.drawPath(path, paint);

    final innerPaint = Paint()..color = paint.color.withValues(alpha: paint.color.a * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size * 0.5, height: size * 0.3),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) {
    if (oldDelegate.t != t) return true;
    for (int i = 0; i < tapValues.length; i++) {
      if (oldDelegate.tapValues[i] != tapValues[i]) return true;
    }
    return false;
  }
}

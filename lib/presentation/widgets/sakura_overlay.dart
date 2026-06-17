import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Floating sakura-petal particle overlay.
///
/// Renders 10 animated petal particles that fall and rotate across the widget.
/// Tap a petal to trigger a fast spin and emit glowing pollen particles.
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
  final List<_Pollen> _pollens = [];
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

    // Update pollen particles on every animation frame
    _controller.addListener(() {
      if (_pollens.isNotEmpty) {
        for (int i = _pollens.length - 1; i >= 0; i--) {
          final p = _pollens[i];
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.05; // slight gravity pull down
          p.opacity -= 0.03;
          if (p.opacity <= 0) {
            _pollens.removeAt(i);
          }
        }
      }
    });
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
        // Spawn glowing pollen particles
        for (int p = 0; p < 8; p++) {
          final angle = _random.nextDouble() * math.pi * 2;
          final speed = 1.0 + _random.nextDouble() * 2.5;
          _pollens.add(_Pollen(
            x: x,
            y: y,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 0.5,
            size: 1.5 + _random.nextDouble() * 2.5,
            opacity: 1.0,
          ));
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
              foregroundPainter: _SakuraPainter(
                _petals,
                _controller.value,
                List.generate(10, (i) => _tapCtrls[i].value),
                _pollens,
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
  final double startY; // 0..1 fractional y offset
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
      AppColorsLight.accent.withValues(alpha: 0.7),
      const Color(0xFFFFC0CB), // classic sakura pink
      const Color(0xFFFFB7C5), // cherry blossom pink
    ];
    return _Petal(
      startX: rng.nextDouble(),
      startY: -(rng.nextDouble() * 0.5),
      speed: 0.08 + rng.nextDouble() * 0.12,
      drift: (rng.nextDouble() - 0.5) * 0.1,
      size: 10.0 + rng.nextDouble() * 10.0,
      rotation: rng.nextDouble() * math.pi * 2,
      opacity: 0.4 + rng.nextDouble() * 0.5,
      color: colors[rng.nextInt(colors.length)],
    );
  }
}

// ── Pollen particle data ──────────────────────────────────────────────────────

class _Pollen {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;

  _Pollen({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SakuraPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t; // 0..1 animation progress
  final List<double> tapValues; // per-petal 0..1 tap animation progress
  final List<_Pollen> pollens;

  const _SakuraPainter(this.petals, this.t, this.tapValues, this.pollens);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw cherry blossom petals
    for (int i = 0; i < petals.length; i++) {
      final petal = petals[i];
      final tapT = tapValues[i];
      final progress = (petal.startY + t * petal.speed) % 1.2;
      final x = (petal.startX + t * petal.drift) % 1.0;
      final y = progress;

      // Extra spin + fade + scale down slightly when tapped
      final angle = petal.rotation + t * math.pi * 2 + tapT * math.pi * 4;
      final opacity = petal.opacity * (1.0 - tapT * 0.85);
      final currentSize = petal.size * (1.0 - tapT * 0.3);

      final baseColor = petal.color.withValues(alpha: opacity);
      final tipColor = const Color(0xFFFFE4E1).withValues(alpha: opacity); // MistyRose soft light pink

      final rect = Rect.fromPoints(
        Offset(-currentSize * 0.5, -currentSize * 1.5),
        Offset(currentSize * 0.5, 0),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [baseColor, tipColor],
        ).createShader(rect);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(angle);
      _drawPetalPath(canvas, paint, currentSize);
      canvas.restore();
    }

    // 2. Draw tapped pollen spark particles
    for (final p in pollens) {
      if (p.opacity <= 0) continue;
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: p.opacity.clamp(0.0, 1.0)) // golden spark
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  void _drawPetalPath(Canvas canvas, Paint paint, double size) {
    final path = Path();
    // Notch at the tip (y = -size * 1.5)
    path.moveTo(0, 0);
    path.cubicTo(-size * 0.4, -size * 0.4, -size * 0.6, -size * 1.0, -size * 0.2, -size * 1.4);
    path.lineTo(0, -size * 1.15); // notch dip
    path.lineTo(size * 0.2, -size * 1.4);
    path.cubicTo(size * 0.6, -size * 1.0, size * 0.4, -size * 0.4, 0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Inner detail gradient line
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: paint.shader == null ? 0.3 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;
    
    final innerPath = Path();
    innerPath.moveTo(0, 0);
    innerPath.lineTo(0, -size * 0.7);
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) {
    if (oldDelegate.t != t) return true;
    if (oldDelegate.pollens.length != pollens.length) return true;
    for (int i = 0; i < tapValues.length; i++) {
      if (oldDelegate.tapValues[i] != tapValues[i]) return true;
    }
    return false;
  }
}

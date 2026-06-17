import 'package:flutter/material.dart';

/// Slow breathing-circle/vignette overlay for the Focus mood.
///
/// Renders a soft, elegant screen-border vignette glow and a subtle inner border
/// that gently expand and contract over a 4-second breathing cycle.
/// Wrapped in [RepaintBoundary] internally.
class BreathOverlay extends StatefulWidget {
  final Widget? child;
  const BreathOverlay({super.key, this.child});

  @override
  State<BreathOverlay> createState() => _BreathOverlayState();
}

class _BreathOverlayState extends State<BreathOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    // Looping with reverse: true creates a smooth, continuous inhale/exhale wave
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine);
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
        animation: _breathAnim,
        builder: (_, child) => CustomPaint(
          foregroundPainter: _BreathPainter(_breathAnim.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _BreathPainter extends CustomPainter {
  final double progress; // 0..1 oscillation value
  static const _color = Color(0xFF2E7D32); // Deep premium green for Focus

  const _BreathPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Outer vignette expands and contracts slightly
    final radius = size.longestSide * (0.8 - progress * 0.06);
    final opacity = 0.05 + progress * 0.15; // 0.05 to 0.20 opacity

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _color.withValues(alpha: 0.0),
          _color.withValues(alpha: opacity * 0.3),
          _color.withValues(alpha: opacity),
        ],
        stops: const [0.6, 0.85, 1.0],
      ).createShader(rect);

    // Draw the vignette radial gradient overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw an elegant pulsing inner frame border
    final borderPaint = Paint()
      ..color = _color.withValues(alpha: opacity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + progress * 2.0;

    canvas.drawRect(
      Rect.fromLTWH(8.0, 8.0, size.width - 16.0, size.height - 16.0),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_BreathPainter old) => old.progress != progress;
}

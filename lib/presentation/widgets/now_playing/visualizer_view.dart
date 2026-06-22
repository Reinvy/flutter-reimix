import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VisualizerParticle {
  double x;
  double y;
  double speedY;
  double size;
  double opacity;
  double phase;
  double driftSpeed;

  VisualizerParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.driftSpeed,
  });
}

class VisualizerView extends StatefulWidget {
  final bool isPlaying;
  final AnimationController controller;
  final Color accentColor;

  const VisualizerView({
    super.key,
    required this.isPlaying,
    required this.controller,
    required this.accentColor,
  });

  @override
  State<VisualizerView> createState() => _VisualizerViewState();
}

class _VisualizerViewState extends State<VisualizerView> {
  final List<Offset> _ripples = [];
  final List<double> _rippleProgresses = [];
  final List<VisualizerParticle> _particles = [];
  late final Timer _timer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize particles
    for (int i = 0; i < 25; i++) {
      _particles.add(_generateParticle(randomY: true));
    }

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        // Update ripples
        for (int i = 0; i < _rippleProgresses.length; i++) {
          if (_rippleProgresses[i] < 1.0) {
            _rippleProgresses[i] += 0.03;
          }
        }
        while (_rippleProgresses.isNotEmpty && _rippleProgresses.first >= 1.0) {
          _ripples.removeAt(0);
          _rippleProgresses.removeAt(0);
        }

        // Update particles if playing
        for (int i = 0; i < _particles.length; i++) {
          final p = _particles[i];
          if (widget.isPlaying) {
            p.y -= p.speedY;
            p.phase += p.driftSpeed;
            p.x += math.sin(p.phase) * 0.4;
            p.opacity -= 0.006;
          } else {
            // Very slow idle animation
            p.y -= p.speedY * 0.2;
            p.phase += p.driftSpeed * 0.2;
            p.x += math.sin(p.phase) * 0.1;
            p.opacity -= 0.001;
          }

          if (p.y < 0 || p.opacity <= 0) {
            _particles[i] = _generateParticle(randomY: false);
          }
        }
      });
    });
  }

  VisualizerParticle _generateParticle({required bool randomY}) {
    return VisualizerParticle(
      x: _random.nextDouble() * 400.0, // Initial guess, adjusted in painter using size.width
      y: randomY ? _random.nextDouble() * 160.0 : 160.0,
      speedY: 0.4 + _random.nextDouble() * 1.2,
      size: 2.0 + _random.nextDouble() * 5.0,
      opacity: 0.3 + _random.nextDouble() * 0.7,
      phase: _random.nextDouble() * math.pi * 2,
      driftSpeed: 0.02 + _random.nextDouble() * 0.05,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _ripples.add(details.localPosition);
      _rippleProgresses.add(0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      child: Center(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (_, __) {
              return CustomPaint(
                size: const Size(double.infinity, 160),
                painter: FluidWavePainter(
                  progress: widget.controller.value,
                  isPlaying: widget.isPlaying,
                  color: widget.accentColor,
                  tapRipples: _ripples,
                  rippleProgresses: _rippleProgresses,
                  particles: _particles,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FluidWavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final List<Offset> tapRipples;
  final List<double> rippleProgresses;
  final List<VisualizerParticle> particles;

  FluidWavePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.tapRipples,
    required this.rippleProgresses,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw particles first (background particles)
    for (final p in particles) {
      // Map x position percentage to actual width dynamically
      final double actualX = (p.x / 400.0) * size.width;
      final double actualSize = p.size * (isPlaying ? 1.0 : 0.6);
      
      final particlePaint = Paint()
        ..color = color.withAlpha((p.opacity * 255).round())
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(actualX, p.y), actualSize, particlePaint);
    }

    const waveCount = 3;
    final waveColors = [
      color.withAlpha(160),
      color.withAlpha(100),
      color.withAlpha(60),
    ];
    final speeds = [1.0, 1.4, 0.7];
    final heights = [18.0, 12.0, 24.0];
    final wavelengths = [size.width * 0.8, size.width * 1.2, size.width * 0.6];

    for (int w = 0; w < waveCount; w++) {
      final paint = Paint()
        ..color = waveColors[w]
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height);

      final currentSpeed = speeds[w];
      final currentHeight = isPlaying ? heights[w] : 3.0;
      final currentWavelength = wavelengths[w];

      for (double x = 0; x <= size.width; x += 4) {
        final angle = (x / currentWavelength) * 2 * math.pi + (progress * 2 * math.pi * currentSpeed);
        final y = size.height / 2 + math.sin(angle) * currentHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw tap ripples on top
    for (int i = 0; i < tapRipples.length; i++) {
      final pos = tapRipples[i];
      final rProgress = rippleProgresses[i];
      if (rProgress >= 1.0) continue;

      final ripplePaint = Paint()
        ..color = color.withAlpha(((1.0 - rProgress) * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(pos, rProgress * 80.0, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(FluidWavePainter oldDelegate) => true;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FutBackground extends StatelessWidget {
  const FutBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF141F2A),
            AppColors.bg,
            Color(0xFF00171B),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: 120,
            child: _GlowOrb(
              color: AppColors.hotPink.withValues(alpha: 0.24),
              size: 320,
            ),
          ),
          Positioned(
            right: -140,
            bottom: 180,
            child: _GlowOrb(
              color: AppColors.neonGreen.withValues(alpha: 0.20),
              size: 360,
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotNoisePainter())),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _DotNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const gap = 36.0;

    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        final jitter = (math.sin(x + y) + 1) * 0.25;
        canvas.drawCircle(Offset(x, y), 1.1 + jitter, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';

class AppBarNaturePainter extends CustomPainter {
  final Animation<double> animation;
  final Brightness brightness;

  AppBarNaturePainter({
    required this.animation,
    required this.brightness,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : AppTheme.primary;

    // Draw subtle floating petals/leaves
    final leafPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final t = (animation.value + (i / 6)) % 1.0;

      // Calculate position
      final x =
          size.width * (0.1 + (i * 0.15) + (0.05 * math.sin(t * 2 * math.pi)));
      final y = size.height * (0.3 + (0.4 * t));

      // Calculate opacity (fade in and out)
      final opacity = 0.15 * math.sin(t * math.pi);
      leafPaint.color = baseColor.withOpacity(opacity);

      // Draw a petal shape
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi + (i * 0.5));

      final path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(8, -8, 0, -16);
      path.quadraticBezierTo(-8, -8, 0, 0);
      path.close();

      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    // Draw gentle glowing particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final t = (animation.value * 0.8 + (i / 8)) % 1.0;
      final x = size.width * ((i * 0.12) + 0.05 * math.cos(t * 4 * math.pi));
      final y = size.height * (0.2 + 0.6 * t);

      final opacity = 0.2 * math.sin(t * math.pi);
      particlePaint.color =
          (isDark ? Colors.white : AppTheme.accent).withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AppBarNaturePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.brightness != brightness;
  }
}

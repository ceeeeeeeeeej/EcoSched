import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';
import 'gradient_background.dart';

class EnhancedNatureBackground extends StatefulWidget {
  final Widget child;
  final bool showPattern;
  final double opacity;
  final bool animateGradient;
  final Duration animationDuration;

  const EnhancedNatureBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.opacity = 1.0,
    this.animateGradient = true,
    this.animationDuration = const Duration(seconds: 12),
  });

  @override
  State<EnhancedNatureBackground> createState() => _EnhancedNatureBackgroundState();
}

class _EnhancedNatureBackgroundState extends State<EnhancedNatureBackground>
    with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late AnimationController _weatherController;
  late AnimationController _breezeController;
  late Animation<double> _parallaxAnimation;
  late Animation<double> _weatherAnimation;
  late Animation<double> _breezeAnimation;

  @override
  void initState() {
    super.initState();
    
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _weatherController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _breezeController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.linear,
    ));

    _weatherAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _weatherController,
      curve: Curves.easeInOut,
    ));

    _breezeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breezeController,
      curve: Curves.easeInOut,
    ));

    _parallaxController.repeat();
    _weatherController.repeat(reverse: true);
    _breezeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _weatherController.dispose();
    _breezeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      showPattern: widget.showPattern,
      opacity: widget.opacity,
      animateGradient: widget.animateGradient,
      animationDuration: widget.animationDuration,
      child: Stack(
        children: [
          // Parallax layers
          if (widget.showPattern) _buildParallaxLayers(),
          
          // Weather effects
          if (widget.showPattern) _buildWeatherEffects(),
          
          // Breeze effects
          if (widget.showPattern) _buildBreezeEffects(),
          
          // Main content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildParallaxLayers() {
    return AnimatedBuilder(
      animation: _parallaxAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Far background mountains
            Positioned.fill(
              child: CustomPaint(
                painter: MountainRangePainter(
                  animation: _parallaxAnimation,
                  layer: 0,
                ),
              ),
            ),
            // Mid background trees
            Positioned.fill(
              child: CustomPaint(
                painter: TreeLinePainter(
                  animation: _parallaxAnimation,
                  layer: 1,
                ),
              ),
            ),
            // Near background elements
            Positioned.fill(
              child: CustomPaint(
                painter: ForegroundElementsPainter(
                  animation: _parallaxAnimation,
                  layer: 2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherEffects() {
    return AnimatedBuilder(
      animation: _weatherAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: WeatherEffectsPainter(
              animation: _weatherAnimation,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreezeEffects() {
    return AnimatedBuilder(
      animation: _breezeAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: BreezeEffectsPainter(
              animation: _breezeAnimation,
            ),
          ),
        );
      },
    );
  }
}

class MountainRangePainter extends CustomPainter {
  final Animation<double> animation;
  final int layer;

  MountainRangePainter({
    required this.animation,
    required this.layer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final offset = animation.value * 50 * (layer + 1);
    
    // Draw mountain silhouettes
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    
    for (int i = 0; i < 5; i++) {
      final x = (i * size.width / 4) + offset;
      final y = size.height * (0.6 + 0.1 * math.sin(i * 0.5));
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TreeLinePainter extends CustomPainter {
  final Animation<double> animation;
  final int layer;

  TreeLinePainter({
    required this.animation,
    required this.layer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final offset = animation.value * 30 * (layer + 1);
    
    // Draw tree silhouettes
    for (int i = 0; i < 8; i++) {
      final x = (i * size.width / 7) + offset;
      final height = 40 + 20 * math.sin(i * 0.8);
      final y = size.height * 0.8 - height;
      
      _drawTree(canvas, Offset(x, y), height, paint);
    }
  }

  void _drawTree(Canvas canvas, Offset base, double height, Paint paint) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy + height * 0.3),
        width: 4,
        height: height * 0.4,
      ),
      paint,
    );
    
    // Foliage
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy),
        width: height * 0.8,
        height: height * 0.6,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ForegroundElementsPainter extends CustomPainter {
  final Animation<double> animation;
  final int layer;

  ForegroundElementsPainter({
    required this.animation,
    required this.layer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final offset = animation.value * 20 * (layer + 1);
    
    // Draw grass blades
    for (int i = 0; i < 15; i++) {
      final x = (i * size.width / 14) + offset;
      final y = size.height * 0.9;
      final height = 15 + 10 * math.sin(i * 0.5);
      
      _drawGrassBlade(canvas, Offset(x, y), height, paint);
    }
  }

  void _drawGrassBlade(Canvas canvas, Offset base, double height, Paint paint) {
    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      base.dx + 2,
      base.dy - height,
      base.dx + 1,
      base.dy - height,
    );
    path.quadraticBezierTo(
      base.dx - 1,
      base.dy - height,
      base.dx,
      base.dy,
    );
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeatherEffectsPainter extends CustomPainter {
  final Animation<double> animation;

  WeatherEffectsPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // Gentle light rays
    final rayPaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.08 * (1 - animation.value))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = (i * math.pi / 3) + animation.value * 0.1;
      final centerX = size.width * 0.2;
      final centerY = size.height * 0.1;
      
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(angle);
      
      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(-15, -size.height * 0.6);
      path.lineTo(15, -size.height * 0.6);
      path.close();
      
      canvas.drawPath(path, rayPaint);
      canvas.restore();
    }

    // Floating pollen/dust particles
    final particlePaint = Paint()
      ..color = AppTheme.accentOrange.withOpacity(0.3 * animation.value)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = (i * 100.0) % size.width + 20 * math.sin(animation.value * 2 * math.pi + i);
      final y = size.height * 0.3 + 30 * math.sin(animation.value * 3 * math.pi + i);
      final radius = 1.0 + 0.5 * math.sin(animation.value * 4 * math.pi + i);
      
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BreezeEffectsPainter extends CustomPainter {
  final Animation<double> animation;

  BreezeEffectsPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw gentle breeze lines
    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.2 + i * size.height * 0.15;
      final waveOffset = 20 * math.sin(animation.value * 2 * math.pi + i);
      
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += 20) {
        final waveY = y + waveOffset * math.sin(x * 0.01 + animation.value * 4 * math.pi);
        path.lineTo(x, waveY);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

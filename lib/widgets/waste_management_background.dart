import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';

class WasteManagementBackground extends StatefulWidget {
  final Widget child;
  final bool showPatterns;
  final bool showAnimations;
  final String? primaryWasteType;

  const WasteManagementBackground({
    super.key,
    required this.child,
    this.showPatterns = true,
    this.showAnimations = true,
    this.primaryWasteType,
  });

  @override
  State<WasteManagementBackground> createState() => _WasteManagementBackgroundState();
}

class _WasteManagementBackgroundState extends State<WasteManagementBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    if (widget.showAnimations) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neutral50,
            AppTheme.primaryGreenLight.withOpacity(0.1),
            AppTheme.neutral100,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (widget.showPatterns)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WasteManagementPatternPainter(
                      animation: _animation,
                      primaryWasteType: widget.primaryWasteType,
                    ),
                  );
                },
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class WasteManagementPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final String? primaryWasteType;

  WasteManagementPatternPainter({
    required this.animation,
    this.primaryWasteType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWasteIcons(canvas, size);
    _drawRecyclingSymbols(canvas, size);
    _drawEconomicCharts(canvas, size);
    _drawWasteFlowLines(canvas, size);
  }

  void _drawWasteIcons(Canvas canvas, Size size) {
    final wasteTypes = ['recycling', 'composting', 'organic', 'hazardous', 'landfill'];
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final wasteType = wasteTypes[i % wasteTypes.length];
      final color = AppTheme.getWasteTypeColor(wasteType);
      final icon = AppTheme.getWasteTypeIcon(wasteType);
      
      final x = (i * 150.0) % size.width;
      final y = (i * 200.0) % size.height;
      final progress = (animation.value + i * 0.1) % 1.0;
      final opacity = 0.1 * (1 - progress);
      
      paint.color = color.withOpacity(opacity);
      
      // Draw icon as simple shapes
      _drawIconShape(canvas, icon, Offset(x, y), 20, paint);
    }
  }

  void _drawRecyclingSymbols(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 5; i++) {
      final x = (i * 200.0) % size.width;
      final y = (i * 150.0) % size.height;
      final progress = (animation.value + i * 0.2) % 1.0;
      final opacity = 0.15 * (1 - progress);
      
      paint.color = AppTheme.recyclingBlue.withOpacity(opacity);
      
      // Draw recycling symbol
      _drawRecyclingSymbol(canvas, Offset(x, y), 30, paint);
    }
  }

  void _drawEconomicCharts(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 6; i++) {
      final x = (i * 180.0) % size.width;
      final y = (i * 120.0) % size.height;
      final progress = (animation.value + i * 0.15) % 1.0;
      final opacity = 0.1 * (1 - progress);
      
      paint.color = AppTheme.efficiencyBlue.withOpacity(opacity);
      
      // Draw chart lines
      _drawChartLines(canvas, Offset(x, y), 40, paint);
    }
  }

  void _drawWasteFlowLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 4; i++) {
      final progress = (animation.value + i * 0.25) % 1.0;
      final opacity = 0.08 * (1 - progress);
      
      paint.color = AppTheme.primaryGreen.withOpacity(opacity);
      
      // Draw flowing lines
      final path = Path();
      final startX = 0.0;
      final startY = size.height * 0.2 + (i * size.height * 0.2);
      final endX = size.width;
      
      path.moveTo(startX, startY);
      for (double x = startX; x < endX; x += 20) {
        final y = startY + 30 * math.sin((x * 0.01) + (progress * 2 * math.pi));
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawIconShape(Canvas canvas, IconData icon, Offset center, double size, Paint paint) {
    // Simplified icon shapes
    switch (icon) {
      case Icons.recycling:
        _drawRecyclingSymbol(canvas, center, size, paint);
        break;
      case Icons.eco:
        _drawEcoSymbol(canvas, center, size, paint);
        break;
      case Icons.park:
        _drawParkSymbol(canvas, center, size, paint);
        break;
      case Icons.warning:
        _drawWarningSymbol(canvas, center, size, paint);
        break;
      case Icons.delete:
        _drawDeleteSymbol(canvas, center, size, paint);
        break;
      default:
        canvas.drawCircle(center, size / 2, paint);
    }
  }

  void _drawRecyclingSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final radius = size / 2;
    
    // Draw three arrows in a triangle
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi) / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      path.moveTo(x, y);
      path.lineTo(x + radius * 0.3 * math.cos(angle + math.pi / 3), 
                  y + radius * 0.3 * math.sin(angle + math.pi / 3));
      path.lineTo(x + radius * 0.3 * math.cos(angle - math.pi / 3), 
                  y + radius * 0.3 * math.sin(angle - math.pi / 3));
      path.close();
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawEcoSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final radius = size / 2;
    
    // Draw leaf shape
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy - radius * 0.3,
      center.dx + radius * 0.3, center.dy + radius * 0.3,
    );
    path.quadraticBezierTo(
      center.dx, center.dy + radius,
      center.dx - radius * 0.3, center.dy + radius * 0.3,
    );
    path.quadraticBezierTo(
      center.dx - radius * 0.5, center.dy - radius * 0.3,
      center.dx, center.dy - radius,
    );
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawParkSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw tree shape
    final trunkRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size * 0.2),
      width: size * 0.2,
      height: size * 0.4,
    );
    canvas.drawRect(trunkRect, paint);
    
    final foliageRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size * 0.1),
      width: size * 0.8,
      height: size * 0.6,
    );
    canvas.drawOval(foliageRect, paint);
  }

  void _drawWarningSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final radius = size / 2;
    
    // Draw warning triangle
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawDeleteSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw trash can
    final canRect = Rect.fromCenter(
      center: center,
      width: size * 0.6,
      height: size * 0.8,
    );
    canvas.drawRect(canRect, paint);
    
    // Draw lid
    final lidRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size * 0.3),
      width: size * 0.8,
      height: size * 0.2,
    );
    canvas.drawRect(lidRect, paint);
  }

  void _drawChartLines(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final step = size / 5;
    
    path.moveTo(center.dx, center.dy);
    for (int i = 1; i <= 5; i++) {
      final x = center.dx + i * step;
      final y = center.dy - (i * step * 0.5) + 10 * math.sin(i * 0.5);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final bool showPattern;
  final double opacity;
  final bool animateGradient;
  final Duration animationDuration;
  final bool economyTheme;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin,
    this.end,
    this.showPattern = true,
    this.opacity = 1.0,
    this.animateGradient = true,
    this.animationDuration = const Duration(seconds: 10),
    this.economyTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    final Color base = theme.scaffoldBackgroundColor;
    final AlignmentGeometry resolvedBegin = begin ?? Alignment.topLeft;
    final AlignmentGeometry resolvedEnd = end ?? Alignment.bottomRight;

    final List<Color> resolvedColors = colors ??
        (economyTheme
            ? <Color>[
                Color.lerp(base, scheme.primary, isDark ? 0.14 : 0.08)!,
                Color.lerp(base, scheme.secondary, isDark ? 0.12 : 0.06)!,
                base,
              ]
            : <Color>[
                Color.lerp(base, scheme.primary, isDark ? 0.12 : 0.06)!,
                Color.lerp(base, scheme.secondary, isDark ? 0.10 : 0.05)!,
                base,
              ]);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            // Use the active theme's scaffold background so dark mode is respected
            color: base,
            gradient: LinearGradient(
              begin: resolvedBegin,
              end: resolvedEnd,
              colors: resolvedColors,
            ),
          ),
        ),
        if (showPattern)
          IgnorePointer(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                color: scheme.primary,
                opacity: opacity,
                isDark: isDark,
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final bool isDark;

  const _BackgroundPatternPainter({
    required this.color,
    required this.opacity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseOpacity = (isDark ? 0.10 : 0.08) * opacity;
    final paint = Paint()..color = color.withValues(alpha: baseOpacity);

    final circles = <Offset, double>{
      const Offset(0.18, 0.22): 120,
      const Offset(0.82, 0.28): 90,
      const Offset(0.68, 0.76): 140,
      const Offset(0.22, 0.78): 110,
    };

    for (final entry in circles.entries) {
      final center =
          Offset(size.width * entry.key.dx, size.height * entry.key.dy);
      canvas.drawCircle(center, entry.value, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.isDark != isDark;
  }
}

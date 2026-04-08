import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? customShadows;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.blur = 15.0,
    this.opacity = 0.15,
    this.color,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final surface = color ?? scheme.surface;
    final double effectiveOpacity = opacity.clamp(0.0, 1.0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface.withOpacity(effectiveOpacity),
                  surface.withOpacity(effectiveOpacity * 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: borderColor ??
                          (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white.withValues(alpha: 0.28)),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: customShadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.12 : 0.03),
                      blurRadius: 60,
                      offset: const Offset(0, 24),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

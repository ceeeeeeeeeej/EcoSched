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
                  (color ?? Colors.white).withOpacity(opacity),
                  (color ?? Colors.white).withOpacity(opacity * 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: borderColor ?? Colors.white.withOpacity(0.3),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: customShadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
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
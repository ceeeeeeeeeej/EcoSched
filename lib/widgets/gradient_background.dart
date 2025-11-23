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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // Use the active theme's scaffold background so dark mode is respected
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: child,
    );
  }
}

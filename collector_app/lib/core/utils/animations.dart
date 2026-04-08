import 'package:flutter/material.dart';

/// Modern animation constants and utilities for EcoSched
class AppAnimations {
  // Duration constants
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 700);

  // Curve constants
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve sharpCurve = Curves.easeInOutCubic;

  // Scale values
  static const double pressedScale = 0.97;
  static const double hoverScale = 1.02;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }

  /// Slide up animation
  static Widget slideUp({
    required Widget child,
    Duration duration = normal,
    Duration delay = Duration.zero,
    double offset = 50.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value),
        child: child,
      ),
      child: child,
    );
  }

  /// Combined fade in + slide up
  static Widget fadeInSlideUp({
    required Widget child,
    Duration duration = normal,
    Duration delay = Duration.zero,
    double offset = 30.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: smoothCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Scale animation for buttons
  static Widget scaleButton({
    required Widget child,
    required bool isPressed,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isPressed ? pressedScale : 1.0),
      duration: ultraFast,
      curve: smoothCurve,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Duration itemDuration = normal,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final delay = staggerDelay * index;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemDuration + delay,
          curve: smoothCurve,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          ),
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Shimmer effect for loading
  static Widget shimmer({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Restart animation automatically
      },
    );
  }

  /// Success celebration animation
  static Widget celebration({
    required Widget child,
    required bool show,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: show ? 1.0 : 0.0),
      duration: slow,
      curve: bouncyCurve,
      builder: (context, value, child) => Transform.scale(
        scale: 0.5 + (value * 0.5),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Shake animation for errors
  static Widget shake({
    required Widget child,
    required bool trigger,
    int shakes = 3,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 50 *  shakes * 2),
      curve: Curves.linear,
      builder: (context, value, child) {
        final shakeValue = (value * shakes * 2).floor() % 2 == 0 ? -5.0 : 5.0;
        final offset = value < 1.0 ? shakeValue : 0.0;
        
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: child,
      onEnd: () {
        // Will automatically reverse
      },
    );
  }
}

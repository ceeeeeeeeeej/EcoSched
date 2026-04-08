import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class NaturePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final NatureTransitionType transitionType;
  final Duration duration;

  NaturePageRoute({
    required this.child,
    this.transitionType = NatureTransitionType.slideUp,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(transitionType, animation, child);
          },
        );

  static Widget _buildTransition(NatureTransitionType type, Animation<double> animation, Widget child) {
    switch (type) {
      case NatureTransitionType.slideUp:
        return _slideUpTransition(animation, child);
      case NatureTransitionType.fadeIn:
        return _fadeInTransition(animation, child);
      case NatureTransitionType.scaleIn:
        return _scaleInTransition(animation, child);
      case NatureTransitionType.rotateIn:
        return _rotateInTransition(animation, child);
      case NatureTransitionType.slideFromRight:
        return _slideFromRightTransition(animation, child);
      case NatureTransitionType.leafFall:
        return _leafFallTransition(animation, child);
    }
  }

  static Widget _slideUpTransition(Animation<double> animation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _fadeInTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }

  static Widget _scaleInTransition(Animation<double> animation, Widget child) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _rotateInTransition(Animation<double> animation, Widget child) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      ),
    );
  }

  static Widget _slideFromRightTransition(Animation<double> animation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  static Widget _leafFallTransition(Animation<double> animation, Widget child) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return CustomPaint(
                painter: LeafFallPainter(
                  progress: animation.value,
                  color: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum NatureTransitionType {
  slideUp,
  fadeIn,
  scaleIn,
  rotateIn,
  slideFromRight,
  leafFall,
}

class LeafFallPainter extends CustomPainter {
  final double progress;
  final Color color;

  LeafFallPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.6 * (1 - progress))
      ..style = PaintingStyle.fill;

    final leafCount = 5;
    for (int i = 0; i < leafCount; i++) {
      final x = (i / leafCount) * size.width;
      final y = progress * size.height + (i * 20);
      final rotation = progress * math.pi * 2 + (i * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(0.5 + 0.5 * math.sin(progress * math.pi));

      _drawLeaf(canvas, paint);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(0, -8);
    path.quadraticBezierTo(6, -4, 8, 0);
    path.quadraticBezierTo(6, 4, 0, 8);
    path.quadraticBezierTo(-6, 4, -8, 0);
    path.quadraticBezierTo(-6, -4, 0, -8);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NatureHeroAnimation extends StatelessWidget {
  final Widget child;
  final String tag;
  final Duration duration;

  const NatureHeroAnimation({
    super.key,
    required this.child,
    required this.tag,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + 0.2 * animation.value,
              child: Transform.rotate(
                angle: (1 - animation.value) * 0.1,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class EcoShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool isActive;

  const EcoShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.duration = const Duration(milliseconds: 1500),
    this.isActive = true,
  });

  @override
  State<EcoShimmerEffect> createState() => _EcoShimmerEffectState();
}

class _EcoShimmerEffectState extends State<EcoShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class NatureBounceAnimation extends StatefulWidget {
  final Widget child;
  final double bounceHeight;
  final Duration duration;
  final bool isActive;

  const NatureBounceAnimation({
    super.key,
    required this.child,
    this.bounceHeight = 10.0,
    this.duration = const Duration(milliseconds: 800),
    this.isActive = true,
  });

  @override
  State<NatureBounceAnimation> createState() => _NatureBounceAnimationState();
}

class _NatureBounceAnimationState extends State<NatureBounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -widget.bounceHeight * _animation.value),
          child: child,
        );
      },
    );
  }
}
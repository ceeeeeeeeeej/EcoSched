import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';

class FloatingLeaves extends StatefulWidget {
  final int leafCount;
  final double speed;
  final Color? leafColor;
  final bool isActive;

  const FloatingLeaves({
    super.key,
    this.leafCount = 8,
    this.speed = 1.0,
    this.leafColor,
    this.isActive = true,
  });

  @override
  State<FloatingLeaves> createState() => _FloatingLeavesState();
}

class _FloatingLeavesState extends State<FloatingLeaves>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<LeafData> _leaves = [];

  @override
  void initState() {
    super.initState();
    _initializeLeaves();
  }

  void _initializeLeaves() {
    _controllers = List.generate(
      widget.leafCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: (3000 + math.Random().nextInt(2000)).round(),
        ),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    for (int i = 0; i < widget.leafCount; i++) {
      _leaves.add(LeafData(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        rotation: math.Random().nextDouble() * 2 * math.pi,
        size: 0.3 + math.Random().nextDouble() * 0.4,
        delay: math.Random().nextDouble() * 2,
      ));
    }

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: (_leaves[i].delay * 1000).round()),
        () {
          if (mounted) {
            _controllers[i].repeat();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(_animations),
        builder: (context, child) {
          return CustomPaint(
            painter: LeavesPainter(
              leaves: _leaves,
              animations: _animations,
              leafColor: widget.leafColor ?? AppTheme.primaryGreen,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class LeafData {
  final double x;
  final double y;
  final double rotation;
  final double size;
  final double delay;

  LeafData({
    required this.x,
    required this.y,
    required this.rotation,
    required this.size,
    required this.delay,
  });
}

class LeavesPainter extends CustomPainter {
  final List<LeafData> leaves;
  final List<Animation<double>> animations;
  final Color leafColor;

  LeavesPainter({
    required this.leaves,
    required this.animations,
    required this.leafColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < leaves.length; i++) {
      if (i < animations.length) {
        final leaf = leaves[i];
        final animation = animations[i];
        
        final paint = Paint()
          ..color = leafColor.withOpacity(0.6 * (1 - animation.value))
          ..style = PaintingStyle.fill;

        final x = leaf.x * size.width;
        final y = leaf.y * size.height + (animation.value * size.height);
        final rotation = leaf.rotation + (animation.value * math.pi * 2);
        final scale = leaf.size * (0.5 + 0.5 * math.sin(animation.value * math.pi));

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);
        canvas.scale(scale);

        _drawLeaf(canvas, paint);
        canvas.restore();
      }
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(0, -10);
    path.quadraticBezierTo(8, -5, 10, 0);
    path.quadraticBezierTo(8, 5, 0, 10);
    path.quadraticBezierTo(-8, 5, -10, 0);
    path.quadraticBezierTo(-8, -5, 0, -10);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final double speed;
  final List<Color> colors;
  final bool isActive;

  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.speed = 1.0,
    this.colors = const [],
    this.isActive = true,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<ParticleData> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeParticles();
  }

  void _initializeParticles() {
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(ParticleData(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: 0.5 + math.Random().nextDouble() * 1.5,
        speed: 0.5 + math.Random().nextDouble() * 1.0,
        colorIndex: math.Random().nextInt(widget.colors.length),
      ));
    }

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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlesPainter(
              particles: _particles,
              animation: _animation,
              colors: widget.colors.isNotEmpty 
                  ? widget.colors 
                  : [AppTheme.primaryGreen, AppTheme.accentOrange, AppTheme.accentBlue],
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class ParticleData {
  final double x;
  final double y;
  final double size;
  final double speed;
  final int colorIndex;

  ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.colorIndex,
  });
}

class ParticlesPainter extends CustomPainter {
  final List<ParticleData> particles;
  final Animation<double> animation;
  final List<Color> colors;

  ParticlesPainter({
    required this.particles,
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = colors[particle.colorIndex % colors.length]
            .withOpacity(0.6 * (1 - animation.value))
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height + (animation.value * size.height * particle.speed);
      final radius = particle.size * (0.5 + 0.5 * math.sin(animation.value * math.pi * 2));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NaturePageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class EcoPulseAnimation extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final bool isActive;

  const EcoPulseAnimation({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(seconds: 2),
    this.isActive = true,
  });

  @override
  State<EcoPulseAnimation> createState() => _EcoPulseAnimationState();
}

class _EcoPulseAnimationState extends State<EcoPulseAnimation>
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
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
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
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class NatureRippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final double maxRadius;
  final Duration duration;
  final VoidCallback? onTap;

  const NatureRippleEffect({
    super.key,
    required this.child,
    this.rippleColor = AppTheme.primaryGreen,
    this.maxRadius = 100.0,
    this.duration = const Duration(milliseconds: 600),
    this.onTap,
  });

  @override
  State<NatureRippleEffect> createState() => _NatureRippleEffectState();
}

class _NatureRippleEffectState extends State<NatureRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _rippleCenter;

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
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _rippleCenter = details.localPosition;
    });
    _controller.forward().then((_) {
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _rippleCenter != null
                ? RipplePainter(
                    center: _rippleCenter!,
                    radius: _animation.value * widget.maxRadius,
                    color: widget.rippleColor,
                  )
                : null,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1 - radius / 100))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

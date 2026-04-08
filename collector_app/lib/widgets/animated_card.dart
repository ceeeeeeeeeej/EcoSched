import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double scaleOnPress;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHapticFeedback;
  final bool enableRipple;
  final Color? rippleColor;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.boxShadow,
    this.scaleOnPress = 0.98,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.enableHapticFeedback = true,
    this.enableRipple = true,
    this.rippleColor,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.animationCurve,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() {
        _isPressed = true;
      });
      _scaleController.forward();
      if (widget.enableRipple) {
        _rippleController.forward();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
      widget.onTap!();
    }
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.boxShadow ?? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  children: [
                    Container(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                    if (widget.enableRipple && _rippleAnimation.value > 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            color: (widget.rippleColor ?? AppTheme.primaryGreen)
                                .withOpacity(0.1 * _rippleAnimation.value),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final Widget child;
  final Widget? leftAction;
  final Widget? rightAction;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double threshold;
  final Duration animationDuration;
  final Curve animationCurve;

  const SwipeableCard({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.threshold = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _dragOffset += details.delta.dx;
        _dragOffset = _dragOffset.clamp(-200.0, 200.0);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });

      if (_dragOffset.abs() > widget.threshold) {
        if (_dragOffset > 0 && widget.onSwipeRight != null) {
          widget.onSwipeRight!();
        } else if (_dragOffset < 0 && widget.onSwipeLeft != null) {
          widget.onSwipeLeft!();
        }
        _controller.forward().then((_) {
          _controller.reset();
        });
      } else {
        _dragOffset = 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Opacity(
              opacity: _isDragging ? 1.0 : _opacityAnimation.value,
              child: Stack(
                children: [
                  widget.child,
                  if (_isDragging && _dragOffset > 0 && widget.rightAction != null)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: widget.rightAction!),
                    ),
                  if (_isDragging && _dragOffset < 0 && widget.leftAction != null)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: widget.leftAction!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

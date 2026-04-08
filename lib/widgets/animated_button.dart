import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isGradient;
  final List<Color>? gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? child; // Custom child

  const AnimatedButton({
    super.key,
    this.text = '', // Made text optional/default empty
    this.child,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isGradient = false,
    this.gradientColors,
    this.borderRadius = 12.0,
    this.padding,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
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

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    _rippleController.forward();
  }


  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height ?? 56,
            decoration: BoxDecoration(
              gradient: widget.isGradient
                  ? LinearGradient(
                      colors: widget.gradientColors ?? AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isGradient
                  ? null
                  : widget.isOutlined
                      ? Colors.transparent
                      : widget.backgroundColor ?? AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.isOutlined
                  ? Border.all(
                      color: widget.backgroundColor ?? AppTheme.primaryGreen,
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppTheme.primaryGreen)
                      .withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: widget.onPressed,
                onTapDown: _onTapDown,
                onTapCancel: _onTapCancel,
                child: Container(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                  child: Stack(
                    children: [
                      Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: widget.textColor ?? Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : widget.child ??
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        color: widget.textColor ?? Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (widget.text != null &&
                                        widget.text!.isNotEmpty)
                                      Text(
                                        widget.text!,
                                        style: TextStyle(
                                          color: widget.textColor ?? Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                      // Ripple effect
                      if (_rippleAnimation.value > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                              color: Colors.white.withOpacity(0.2 * _rippleAnimation.value),
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
      ),
    );
  }
}
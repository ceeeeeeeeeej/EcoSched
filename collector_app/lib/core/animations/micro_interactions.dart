import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool showFloatingLabel;
  final bool showNatureEffects;
  final Color? primaryColor;
  final Color? accentColor;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.showFloatingLabel = true,
    this.showNatureEffects = true,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _shakeController;
  late AnimationController _successController;
  late AnimationController _floatingLabelController;
  late AnimationController _natureEffectController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _shakeAnimation;
  late Animation<double> _successAnimation;
  late Animation<double> _floatingLabelAnimation;
  late Animation<double> _natureEffectAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;
  bool _isValid = false;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _focusNode.addListener(_onFocusChange);
  }

  void _initializeAnimations() {
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingLabelController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _natureEffectController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(10, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _floatingLabelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingLabelController,
      curve: Curves.easeInOut,
    ));

    _natureEffectAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _natureEffectController,
      curve: Curves.easeInOut,
    ));

    // Start nature effect animation loop
    if (widget.showNatureEffects) {
      _natureEffectController.repeat(reverse: true);
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _focusController.forward();
      _floatingLabelController.forward();
      HapticFeedback.lightImpact();
    } else {
      _focusController.reverse();
      if (!_hasText) {
        _floatingLabelController.reverse();
      }
      _validateField();
    }
  }

  void _onTextChange(String value) {
    setState(() {
      _hasText = value.isNotEmpty;
    });

    if (value.isNotEmpty && !_isFocused) {
      _floatingLabelController.forward();
    } else if (value.isEmpty && !_isFocused) {
      _floatingLabelController.reverse();
    }
  }

  void _validateField() {
    if (widget.validator != null && widget.controller != null) {
      final error = widget.validator!(widget.controller!.text);
      setState(() {
        _hasError = error != null;
        _isValid = !_hasError && widget.controller!.text.isNotEmpty;
      });

      if (_hasError) {
        _shakeController.forward().then((_) {
          _shakeController.reset();
        });
        HapticFeedback.heavyImpact();
      } else if (_isValid) {
        _successController.forward();
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _floatingLabelController.dispose();
    _natureEffectController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? AppTheme.primaryGreen;
    final accentColor = widget.accentColor ?? AppTheme.accentOrange;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color textColor = colorScheme.onSurface;
    final Color hintColor = textColor.withValues(alpha: 0.6);
    final Color idleFillColor =
        isDark ? AppTheme.neutral800 : AppTheme.neutral50;
    final Color idleIconBackground =
        isDark ? AppTheme.neutral700 : AppTheme.neutral100;
    final Color idleIconColor = isDark ? Colors.white70 : AppTheme.textMuted;
    final Color idleBorderColor = _hasError
        ? AppTheme.errorRed.withValues(alpha: 0.3)
        : (isDark ? Colors.white24 : AppTheme.neutral200);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _glowAnimation,
        _shakeAnimation,
        _successAnimation,
        _floatingLabelAnimation,
        _natureEffectAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _shakeAnimation,
            child: Stack(
              children: [
                // Nature effect background
                if (widget.showNatureEffects)
                  Positioned.fill(
                    child:
                        _buildNatureEffectBackground(primaryColor, accentColor),
                  ),

                // Main text field container
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    gradient: _isFocused
                        ? LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.05),
                              accentColor.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: primaryColor
                                  .withValues(alpha: 0.2 * _glowAnimation.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: primaryColor
                                  .withValues(alpha: 0.1 * _glowAnimation.value),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                               color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: Stack(
                      children: [
                        // Floating label
                        if (widget.showFloatingLabel &&
                            widget.labelText != null)
                          Positioned(
                            top: 8,
                            left: 16,
                            child: AnimatedBuilder(
                              animation: _floatingLabelAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0,
                                      -8 * (1 - _floatingLabelAnimation.value)),
                                  child: Opacity(
                                    opacity: _floatingLabelAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.labelText!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _hasError
                                              ? AppTheme.errorRed
                                              : _isFocused
                                                  ? primaryColor
                                                  : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Text field
                        TextFormField(
                          controller: widget.controller,
                          focusNode: widget.focusNode ?? _focusNode,
                          obscureText: widget.obscureText,
                          keyboardType: widget.keyboardType,
                          validator: widget.validator,
                          onChanged: (value) {
                            _onTextChange(value);
                            widget.onChanged?.call(value);
                          },
                          textInputAction: widget.textInputAction,
                          onFieldSubmitted: widget.onSubmitted != null
                              ? (_) => widget.onSubmitted!()
                              : null,
                          enabled: widget.enabled,
                          maxLines: widget.maxLines,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            labelText: widget.showFloatingLabel
                                ? null
                                : widget.labelText,
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 16,
                            ),
                            prefixIcon: widget.prefixIcon != null
                                ? Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isFocused
                                          ? primaryColor.withValues(alpha: 0.1)
                                          : idleIconBackground,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      widget.prefixIcon,
                                      color: _isFocused
                                          ? primaryColor
                                          : idleIconColor,
                                      size: 20,
                                    ),
                                  )
                                : null,
                            suffixIcon: _buildSuffixIcon(
                              primaryColor,
                              idleIconBackground,
                              idleIconColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL),
                              borderSide: BorderSide(
                                color: idleBorderColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL),
                              borderSide: BorderSide(
                                color: AppTheme.errorRed,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL),
                              borderSide: BorderSide(
                                color: AppTheme.errorRed,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                _isFocused ? Colors.transparent : idleFillColor,
                            contentPadding: EdgeInsets.only(
                              left: widget.prefixIcon != null ? 0 : 16,
                              right: widget.suffixIcon != null ? 0 : 16,
                              top: widget.showFloatingLabel ? 20 : 16,
                              bottom: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNatureEffectBackground(Color primaryColor, Color accentColor) {
    return CustomPaint(
      painter: NatureTextFieldPainter(
        animation: _natureEffectAnimation,
        primaryColor: primaryColor,
        accentColor: accentColor,
        isFocused: _isFocused,
      ),
    );
  }

  Widget? _buildSuffixIcon(
      Color primaryColor, Color idleIconBackground, Color idleIconColor) {
    if (widget.suffixIcon != null) {
      return Container(
        margin: const EdgeInsets.all(12),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFocused
                  ? primaryColor.withValues(alpha: 0.1)
                  : AppTheme.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.suffixIcon,
              color: _isFocused ? primaryColor : AppTheme.textMuted,
              size: 20,
            ),
          ),
          onPressed: widget.onSuffixTap,
        ),
      );
    }

    if (_isValid) {
      return Container(
        margin: const EdgeInsets.all(12),
        child: AnimatedBuilder(
          animation: _successAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _successAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
              ),
            );
          },
        ),
      );
    }

    return null;
  }
}

class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final String? label;
  final bool enabled;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.label,
    this.enabled = true,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    if (widget.value) {
      _checkController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        _checkController.forward();
        HapticFeedback.lightImpact();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.enabled ? () => widget.onChanged?.call(!widget.value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _checkAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.value
                        ? (widget.activeColor ?? AppTheme.primaryGreen)
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.value
                          ? (widget.activeColor ?? AppTheme.primaryGreen)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: widget.value
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            },
          ),
          if (widget.label != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.label!,
              style: TextStyle(
                color: widget.enabled ? AppTheme.textDark : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AnimatedRadio<T> extends StatefulWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;
  final String? label;
  final bool enabled;

  const AnimatedRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.activeColor,
    this.label,
    this.enabled = true,
  });

  @override
  State<AnimatedRadio<T>> createState() => _AnimatedRadioState<T>();
}

class _AnimatedRadioState<T> extends State<AnimatedRadio<T>>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == widget.groupValue &&
        oldWidget.value != widget.groupValue) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _pulseController.forward().then((_) {
        _pulseController.reset();
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.value == widget.groupValue;

    return GestureDetector(
      onTap: widget.enabled ? () => widget.onChanged?.call(widget.value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (widget.activeColor ?? AppTheme.primaryGreen)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  widget.activeColor ?? AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
          if (widget.label != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.label!,
              style: TextStyle(
                color: widget.enabled ? AppTheme.textDark : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NatureTextFieldPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color accentColor;
  final bool isFocused;

  NatureTextFieldPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.isFocused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isFocused) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i / 3) % 1.0;
      final x = size.width * 0.1 + (i * size.width * 0.3);
      final y = size.height * 0.2 + 20 * math.sin(progress * 2 * math.pi);
      final radius = 2.0 + 1.0 * math.sin(progress * 4 * math.pi);
      final opacity = 0.3 * (1 - progress);

      paint.color =
          (i % 2 == 0 ? primaryColor : accentColor).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw gentle wave pattern
    final wavePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (double x = 0; x < size.width; x += 2) {
      final y = size.height * 0.8 +
          5 * math.sin((x * 0.02) + (animation.value * 2 * math.pi));
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

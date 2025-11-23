import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class AnimatedChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final IconData? icon;
  final IconData? selectedIcon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHapticFeedback;

  const AnimatedChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.icon,
    this.selectedIcon,
    this.borderRadius = 20.0,
    this.padding,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.elasticOut,
    this.enableHapticFeedback = true,
  });

  @override
  State<AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<AnimatedChip>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _iconController;
  
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _textColorAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

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
    
    _colorController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.unselectedColor ?? Colors.grey[200],
      end: widget.selectedColor ?? AppTheme.primaryGreen,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: widget.animationCurve,
    ));

    _textColorAnimation = ColorTween(
      begin: widget.unselectedTextColor ?? AppTheme.textDark,
      end: widget.selectedTextColor ?? Colors.white,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: widget.animationCurve,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    if (widget.isSelected) {
      _colorController.forward();
      _iconController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _colorController.forward();
        _iconController.forward();
        if (widget.enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
      } else {
        _colorController.reverse();
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _colorAnimation,
          _textColorAnimation,
          _iconScaleAnimation,
          _iconRotationAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.isSelected
                      ? (widget.selectedColor ?? AppTheme.primaryGreen)
                      : Colors.grey[300]!,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: (widget.selectedColor ?? AppTheme.primaryGreen)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null || widget.selectedIcon != null)
                    Transform.scale(
                      scale: _iconScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _iconRotationAnimation.value * 3.14159,
                        child: Icon(
                          widget.isSelected
                              ? (widget.selectedIcon ?? widget.icon)
                              : widget.icon,
                          color: _textColorAnimation.value,
                          size: 16,
                        ),
                      ),
                    ),
                  if (widget.icon != null || widget.selectedIcon != null)
                    const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _textColorAnimation.value,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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

class AnimatedChipGroup extends StatefulWidget {
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String>? onSelectionChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final IconData? icon;
  final IconData? selectedIcon;
  final double spacing;
  final double runSpacing;
  final bool allowMultipleSelection;
  final List<String>? selectedOptions;

  const AnimatedChipGroup({
    super.key,
    required this.options,
    this.selectedOption,
    this.onSelectionChanged,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.icon,
    this.selectedIcon,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.allowMultipleSelection = false,
    this.selectedOptions,
  });

  @override
  State<AnimatedChipGroup> createState() => _AnimatedChipGroupState();
}

class _AnimatedChipGroupState extends State<AnimatedChipGroup> {
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.selectedOptions ?? 
        (widget.selectedOption != null ? [widget.selectedOption!] : []);
  }

  @override
  void didUpdateWidget(AnimatedChipGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOptions != oldWidget.selectedOptions) {
      _selectedOptions = widget.selectedOptions ?? [];
    }
  }

  void _handleSelection(String option) {
    setState(() {
      if (widget.allowMultipleSelection) {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      } else {
        _selectedOptions = [option];
      }
    });
    
    if (widget.onSelectionChanged != null) {
      if (widget.allowMultipleSelection) {
        // For multiple selection, you might want to pass all selected options
        // This is a simplified version - you might want to modify based on your needs
        widget.onSelectionChanged!(option);
      } else {
        widget.onSelectionChanged!(option);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: widget.options.map((option) {
        final isSelected = _selectedOptions.contains(option);
        return AnimatedChip(
          label: option,
          isSelected: isSelected,
          onTap: () => _handleSelection(option),
          selectedColor: widget.selectedColor,
          unselectedColor: widget.unselectedColor,
          selectedTextColor: widget.selectedTextColor,
          unselectedTextColor: widget.unselectedTextColor,
          icon: widget.icon,
          selectedIcon: widget.selectedIcon,
        );
      }).toList(),
    );
  }
}

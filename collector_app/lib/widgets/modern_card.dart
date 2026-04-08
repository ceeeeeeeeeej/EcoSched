import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/animations.dart';

/// Modern elevated card with press animation and gradient support
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final Color? color;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enablePressEffect;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.color,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.enablePressEffect = true,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.smoothCurve,
      decoration: BoxDecoration(
        gradient: widget.gradient != null
            ? LinearGradient(
                colors: widget.gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: widget.color ?? Theme.of(context).cardTheme.color,
        borderRadius: widget.borderRadius ?? AppTheme.borderRadiusXL,
        boxShadow: _isPressed && widget.enablePressEffect
            ? AppTheme.shadowSmall
            : AppTheme.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.enablePressEffect
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enablePressEffect
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enablePressEffect
              ? () => setState(() => _isPressed = false)
              : null,
          borderRadius: widget.borderRadius ?? AppTheme.borderRadiusXL,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacing4),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.enablePressEffect) {
      return AppAnimations.scaleButton(
        isPressed: _isPressed,
        child: card,
      );
    }

    return card;
  }
}

/// Modern action card with icon and title
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final Widget? badge;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.gradient,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGradient = gradient != null;

    return ModernCard(
      onTap: onTap,
      gradient: gradient,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            decoration: BoxDecoration(
              color: hasGradient
                  ? Colors.white.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: Icon(
              icon,
              color: hasGradient ? Colors.white : AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: hasGradient ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasGradient
                          ? Colors.white.withOpacity(0.9)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppTheme.spacing2),
            badge!,
          ],
          const SizedBox(width: AppTheme.spacing2),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: hasGradient ? Colors.white : AppTheme.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

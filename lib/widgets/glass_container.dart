// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../theme/app_theme.dart';

// /// Modern glassmorphism container with frosted glass effect
// class GlassContainer extends StatelessWidget {
//   final Widget child;
//   final double blur;
//   final double opacity;
//   final BorderRadius? borderRadius;
//   final EdgeInsets? padding;
//   final Color? color;
//   final Border? border;
//   final List<BoxShadow>? boxShadow;

//   const GlassContainer({
//     super.key,
//     required this.child,
//     this.blur = 10.0,
//     this.opacity = 0.2,
//     this.borderRadius,
//     this.padding,
//     this.color,
//     this.border,
//     this.boxShadow,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final defaultColor = isDark
//         ? Colors.white.withOpacity(opacity)
//         : Colors.white.withOpacity(opacity + 0.1);

//     return ClipRRect(
//       borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusL),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             color: color ?? defaultColor,
//             borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusL),
//             border: border ??
//                 Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1.5,
//                 ),
//             boxShadow: boxShadow,
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// /// Premium glassmorphism card
// class GlassCard extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets? padding;
//   final VoidCallback? onTap;
//   final double blur;

//   const GlassCard({
//     super.key,
//     required this.child,
//     this.padding,
//     this.onTap,
//     this.blur = 10.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final content = GlassContainer(
//       blur: blur,
//       padding: padding ?? const EdgeInsets.all(AppTheme.spacing4),
//       boxShadow: AppTheme.shadowMedium,
//       child: child,
//     );

//     if (onTap != null) {
//       return InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(AppTheme.radiusL),
//         child: content,
//       );
//     }

//     return content;
//   }
// }

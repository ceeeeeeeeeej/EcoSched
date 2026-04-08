import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/app_theme.dart';
import 'app_bar_nature_painter.dart';

class PremiumAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  @override
  State<PremiumAppBar> createState() => _PremiumAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PremiumAppBarState extends State<PremiumAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.backgroundSecondary.withOpacity(0.7)
                : AppTheme.primary.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: AppBarNaturePainter(
                    animation: _controller,
                    brightness: theme.brightness,
                  ),
                ),
              ),
              AppBar(
                title: widget.title,
                centerTitle: widget.centerTitle,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: widget.actions,
                foregroundColor: AppTheme.textInverse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

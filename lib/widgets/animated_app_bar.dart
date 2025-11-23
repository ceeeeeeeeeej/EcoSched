import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final ScrollController? scrollController;
  final double scrollThreshold;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedAppBar({
    super.key,    
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
    this.scrollController,
    this.scrollThreshold = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AnimatedAppBarState extends State<AnimatedAppBar>
    with TickerProviderStateMixin {
  late AnimationController _elevationController;
  late AnimationController _fadeController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _elevationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.elevation,
    ).animate(CurvedAnimation(
      parent: _elevationController,
      curve: widget.animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: widget.animationCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: widget.animationCurve,
    ));
  }

  void _setupScrollListener() {
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (widget.scrollController == null) return;

    final offset = widget.scrollController!.offset;
    final shouldBeScrolled = offset > widget.scrollThreshold;

    if (shouldBeScrolled != _isScrolled) {
      setState(() {
        _isScrolled = shouldBeScrolled;
      });

      if (_isScrolled) {
        _elevationController.forward();
        _fadeController.forward();
      } else {
        _elevationController.reverse();
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    _elevationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_elevationAnimation, _fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1 * _elevationAnimation.value),
                blurRadius: 8 * _elevationAnimation.value,
                offset: Offset(0, 2 * _elevationAnimation.value),
              ),
            ],
          ),
          child: AppBar(
            title: widget.title != null
                ? Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                          color: widget.foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : null,
            actions: widget.actions?.map((action) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: action,
                ),
              );
            }).toList(),
            leading: widget.leading != null
                ? Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: widget.leading!,
                    ),
                  )
                : null,
            centerTitle: widget.centerTitle,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: widget.foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
          ),
        );
      },
    );
  }
}

class AnimatedSliverAppBar extends StatefulWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double expandedHeight;
  final double collapsedHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ScrollController? scrollController;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight = 200.0,
    this.collapsedHeight = kToolbarHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.scrollController,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedSliverAppBar> createState() => _AnimatedSliverAppBarState();
}

class _AnimatedSliverAppBarState extends State<AnimatedSliverAppBar>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: widget.animationCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: widget.title != null
          ? AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        color: widget.foregroundColor ?? AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
      actions: widget.actions?.map((action) {
        return AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: action,
              ),
            );
          },
        );
      }).toList(),
      leading: widget.leading != null
          ? AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: widget.leading!,
                  ),
                );
              },
            )
          : null,
      flexibleSpace: widget.flexibleSpace ?? _buildDefaultFlexibleSpace(),
      pinned: widget.pinned,
      floating: widget.floating,
      snap: widget.snap,
      expandedHeight: widget.expandedHeight,
      collapsedHeight: widget.collapsedHeight,
      backgroundColor: widget.backgroundColor ?? AppTheme.cardWhite,
      foregroundColor: widget.foregroundColor ?? AppTheme.textDark,
      elevation: 0,
    );
  }

  Widget _buildDefaultFlexibleSpace() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.primaryGradient,      
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: const Icon(
                  Icons.eco,
                  size: 60,
                  color: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

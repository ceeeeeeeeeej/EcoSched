import 'dart:async';
import 'package:flutter/material.dart';

class EasyTouchChatButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration idleHideDuration;
  final double size;
  final EdgeInsets margin;

  const EasyTouchChatButton({
    super.key,
    required this.onPressed,
    this.idleHideDuration = const Duration(seconds: 4),
    this.size = 56,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  State<EasyTouchChatButton> createState() => _EasyTouchChatButtonState();
}

class _EasyTouchChatButtonState extends State<EasyTouchChatButton> {
  Offset? _position;
  double _opacity = 1.0;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() {
      _opacity = 1.0;
    });
    _hideTimer = Timer(widget.idleHideDuration, () {
      if (mounted) {
        setState(() {
          _opacity = 0.15; // nearly invisible when idle
        });
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size bounds) {
    final double maxX = bounds.width - widget.size - widget.margin.right;
    final double maxY = bounds.height - widget.size - widget.margin.bottom - 24; // keep above system nav
    final double minX = widget.margin.left;
    final double minY = widget.margin.top;

    final Offset next = Offset(
      (_position?.dx ?? maxX) + details.delta.dx,
      (_position?.dy ?? maxY) + details.delta.dy,
    );

    setState(() {
      _position = Offset(
        next.dx.clamp(minX, maxX),
        next.dy.clamp(minY, maxY),
      );
    });
  }

  void _onPanEnd(Size bounds) {
    if (_position == null) return;
    final double midX = bounds.width / 2;
    final bool snapLeft = _position!.dx + widget.size / 2 < midX;
    final double targetX = snapLeft
        ? widget.margin.left
        : bounds.width - widget.size - widget.margin.right;
    setState(() {
      _position = Offset(targetX, _position!.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This widget must be used as a direct child of a Stack
    final Size screen = MediaQuery.of(context).size;
    final Size bounds = Size(
      screen.width,
      screen.height,
    );

    final double defaultLeft = bounds.width - widget.size - widget.margin.right;
    final double defaultTop = bounds.height - widget.size - widget.margin.bottom - 80;
    final double left = _position?.dx ?? defaultLeft;
    final double top = _position?.dy ?? defaultTop;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) => _resetHideTimer(),
        onPanUpdate: (d) {
          _resetHideTimer();
          _onPanUpdate(d, bounds);
        },
        onPanEnd: (_) => _onPanEnd(bounds),
        onTap: () {
          _resetHideTimer();
          widget.onPressed();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: Icon(Icons.chat_bubble_outline, color: Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



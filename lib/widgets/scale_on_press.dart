// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PressHaptic { none, selection, light, medium, heavy }

                                                                               
                                                                            
                                     
class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final PressHaptic haptic;

  const ScaleOnPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 110),
    this.haptic = PressHaptic.selection,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && !_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && _isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && _isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  Future<void> _playHaptic() async {
    try {
      switch (widget.haptic) {
        case PressHaptic.none:
          return;
        case PressHaptic.selection:
          await HapticFeedback.selectionClick();
          return;
        case PressHaptic.light:
          await HapticFeedback.lightImpact();
          return;
        case PressHaptic.medium:
          await HapticFeedback.mediumImpact();
          return;
        case PressHaptic.heavy:
          await HapticFeedback.heavyImpact();
          return;
      }
    } catch (_) {
      return;
    }
  }

  void _handleTap() {
    unawaited(_playHaptic());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return Semantics(
      button: true,
      enabled: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
        ),
      ),
    );
  }
}

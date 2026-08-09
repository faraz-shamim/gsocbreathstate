import 'dart:ui';

import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

                                        
   
                                                                       
                                                                        
                                                                      
                                                              
class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool hasBorder;

                                                                        
                                                              
  final bool sheen;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusMd,
    this.color,
    this.hasBorder = false,
    this.sheen = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

                                                                        
    final baseSurface = isDark
        ? AppTheme.darkSurface.withValues(alpha: 0.90)
        : AppTheme.ivory.withValues(alpha: 0.96);
    final tintOpacity = isDark ? 0.14 : 0.08;
    final surface = widget.color == null
        ? baseSurface
        : Color.alphaBlend(
            widget.color!.withValues(alpha: tintOpacity),
            baseSurface,
          );

                                                                        
    final borderColor = AppTheme.hairline(isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _hovering ? 1.004 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppTheme.softShadow(isDark: isDark, bright: _hovering),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: widget.padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: radius,
                  border: widget.hasBorder
                      ? Border.all(color: borderColor, width: 1)
                      : null,
                  gradient: widget.sheen
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.alphaBlend(
                              Colors.white
                                  .withValues(alpha: isDark ? 0.04 : 0.16),
                              surface,
                            ),
                            surface,
                          ],
                        )
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/material.dart';

                                                                    
   
                                                                   
                                                                    
   
           
                    
                       
                       
                     
                                                                  
     
       
class AnimatedCounter extends ImplicitlyAnimatedWidget {
  final double value;
  final int decimalPlaces;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimalPlaces = 0,
    this.style,
    this.suffix,
    this.prefix,
    super.duration = const Duration(milliseconds: 600),
    super.curve = Curves.easeOutCubic,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedCounter> createState() =>
      _AnimatedCounterState();
}

class _AnimatedCounterState
    extends AnimatedWidgetBaseState<AnimatedCounter> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value,
      (dynamic val) => Tween<double>(begin: val as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _valueTween?.evaluate(animation) ?? widget.value;
    final formatted = currentValue.toStringAsFixed(widget.decimalPlaces);

    final effectiveStyle = (widget.style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text(
      '${widget.prefix ?? ''}$formatted${widget.suffix ?? ''}',
      style: effectiveStyle,
    );
  }
}

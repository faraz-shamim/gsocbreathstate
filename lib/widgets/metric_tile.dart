// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

                                   
   
                                                                        
                                                                         
                                             
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool compact;
  final Color? accentColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
    this.compact = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccent = accentColor != null;

                                                                        
    final Color baseBg = isDark
        ? Colors.white.withValues(alpha: 0.035)
        : const Color(0xFFF6F4F0);
    final Color bg = hasAccent
        ? Color.alphaBlend(
            accentColor!.withValues(alpha: isDark ? 0.09 : 0.07),
            baseBg,
          )
        : baseBg;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: compact ? 7 : 11,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                                           
          if (hasAccent && !compact) ...[
            Container(
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 7),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.52)
                  : const Color(0xFF6B6760),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

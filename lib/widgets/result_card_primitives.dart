import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

                                                                 
   
                                                                        
                                                                          
                                                                        
                                                          

                                                  
class ResultBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final IconData? icon;

  const ResultBadge({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

                                                                       
                                                                            
class ResultDivider extends StatelessWidget {
  final bool isDark;

  const ResultDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fade = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, fade, Colors.transparent],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

                                                                      
                                                         
class InsightBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;

  const InsightBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: isDark ? 0.95 : 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

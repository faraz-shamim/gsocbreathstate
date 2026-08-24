// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

                                                               
                                                   
class SessionHistoryCard extends StatelessWidget {
  final List<SessionSummary> sessions;
  final VoidCallback onTap;

  const SessionHistoryCard({
    super.key,
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = sessions.length;
    final lastSession = sessions.isNotEmpty ? sessions.first : null;
    final lastDt =
        lastSession != null ? DateTime.tryParse(lastSession.startedAt) : null;
    final lastStr =
        lastDt != null ? DateFormat('MMM d, h:mm a').format(lastDt) : null;

    return ScaleOnPress(
      onTap: onTap,
      scaleFactor: 0.985,
      haptic: PressHaptic.light,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.emerald,
                      AppTheme.emerald.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      count == 0
                          ? 'No sessions recorded'
                          : '$count session${count == 1 ? '' : 's'}${lastStr != null ? '  *  Last: $lastStr' : ''}',
                      style: AppTheme.luxuryItalic(
                        fontSize: 11,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
                            
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emerald,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

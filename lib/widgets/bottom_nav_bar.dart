// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:ui';

import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const double _contentHeight = 72;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;
    final horizontalPadding = compact ? 6.0 : 10.0;
    final verticalPadding = compact ? 5.0 : 7.0;

    return SizedBox(
      width: double.infinity,
      height: _contentHeight + bottomInset,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppTheme.charcoal.withValues(alpha: 0.88)
                      : AppTheme.pureWhite.withValues(alpha: 0.96),
              border: Border(
                top: BorderSide(
                  color: AppTheme.hairline(isDark),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                  blurRadius: 30,
                  spreadRadius: -18,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                bottomInset + verticalPadding,
              ),
              child: Consumer2<NavBarProvider, AppModeProvider>(
                builder: (context, navBarProvider, appModeProvider, child) {
                  final currentIndex = navBarProvider.getIndex();
                  final dests = appModeProvider.destinations;

                  return Row(
                    children: List.generate(dests.length, (index) {
                      final dest = dests[index];
                      return Expanded(
                        child: _NavBarItem(
                          icon: dest.icon,
                          activeIcon: dest.activeIcon,
                          label: dest.label,
                          index: index,
                          currentIndex: currentIndex,
                          compact: compact,
                          onTap: () => navBarProvider.changeIndex(index),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final bool compact;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.emerald : AppTheme.deepJade;
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.58) : const Color(0xFF64748B);

    return Tooltip(
      message: label,
      child: ScaleOnPress(
        onTap: onTap,
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.14 : 0.10)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: Icon(
                  isSelected ? (activeIcon ?? icon) : icon,
                  key: ValueKey('${label}_$isSelected'),
                  color: isSelected ? activeColor : inactiveColor,
                  size: compact ? 20 : 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: compact ? 10 : 11,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

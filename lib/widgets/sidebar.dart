// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:ui';

import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/screens/patient_list_screen.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

                                                             

class AppSidebar extends StatelessWidget {
  final bool expanded;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AppSidebar({
    super.key,
    required this.expanded,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  double get _width =>
      expanded ? Responsive.sidebarExpanded : Responsive.sidebarCollapsed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appModeProvider = context.watch<AppModeProvider>();
    final dests = appModeProvider.destinations;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: _width,
      decoration: BoxDecoration(
        color:
            isDark
                ? AppTheme.obsidian.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.96),
        border: Border(
          right: BorderSide(
            color: AppTheme.hairline(isDark),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
            blurRadius: 32,
            spreadRadius: -20,
            offset: const Offset(14, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                const SizedBox(height: 18),
                _Branding(expanded: expanded),
                const SizedBox(height: 28),
                ...List.generate(dests.length, (index) {
                  return _SidebarItem(
                    destination: dests[index],
                    isSelected: index == currentIndex,
                    expanded: expanded,
                    onTap: () => onIndexChanged(index),
                  );
                }),
                const Spacer(),
                if (!appModeProvider.isPatientWithoutPolar) ...[
                  _PatientSection(expanded: expanded),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  final bool expanded;

  const _Branding({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 18 : 0),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.emerald,
                  AppTheme.softSage.withValues(alpha: 0.86),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emerald.withValues(
                    alpha: isDark ? 0.22 : 0.18,
                  ),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.air_rounded,
              color: AppTheme.pureWhite,
              size: 23,
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'BreathState',
                style: AppTheme.luxuryItalic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavDestination destination;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.emerald : AppTheme.deepJade;
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.64) : const Color(0xFF64748B);
    final hoverBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF6FF);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.expanded ? 12 : 8,
        vertical: 3,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.destination.label,
          waitDuration: const Duration(milliseconds: 500),
          child: ScaleOnPress(
            onTap: widget.onTap,
            scaleFactor: 0.98,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 210),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 46),
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 12 : 0,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color:
                    widget.isSelected
                        ? activeColor.withValues(alpha: isDark ? 0.14 : 0.09)
                        : _hovering
                        ? hoverBg
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                                                      
                                       
                border: widget.isSelected
                    ? Border(
                        left: BorderSide(
                          color: activeColor,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment:
                    widget.expanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isSelected
                        ? (widget.destination.activeIcon ??
                            widget.destination.icon)
                        : widget.destination.icon,
                    color: widget.isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.destination.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              widget.isSelected ? activeColor : inactiveColor,
                          fontWeight:
                              widget.isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                          letterSpacing: 0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientSection extends StatelessWidget {
  final bool expanded;

  const _PatientSection({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.emerald : AppTheme.deepJade;

    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        final name = provider.activePatient?.name ?? 'Select';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 8),
          child: Tooltip(
            message: expanded ? 'Switch patient' : name,
            child: ScaleOnPress(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientListScreen(),
                    ),
                  ),
              scaleFactor: 0.98,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 210),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 12 : 0,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: Row(
                  mainAxisAlignment:
                      expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: activeColor,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pureWhite,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color:
                                isDark ? AppTheme.textLight : AppTheme.textDark,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 17,
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.48)
                                : const Color(0xFF64748B),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

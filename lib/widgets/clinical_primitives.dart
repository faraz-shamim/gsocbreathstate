import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ClinicalPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? tint;
  final bool elevated;
  final bool constrained;

  const ClinicalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = AppTheme.radiusMd,
    this.tint,
    this.elevated = false,
    this.constrained = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = AppTheme.panelFill(isDark);
    final fill = tint == null
        ? base
        : Color.alphaBlend(tint!.withValues(alpha: isDark ? 0.08 : 0.06), base);

    return Container(
      margin: margin,
      constraints: constrained ? const BoxConstraints(maxWidth: 620) : null,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.hairline(isDark)),
        boxShadow: elevated ? AppTheme.softShadow(isDark: isDark) : null,
      ),
      child: child,
    );
  }
}

class ClinicalSectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? trailing;

  const ClinicalSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted(isDark),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: textTheme.titleMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ClinicalStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ClinicalStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? color : Color.alphaBlend(color, AppTheme.textDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicalMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String caption;
  final Color color;

  const ClinicalMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.caption = '',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return ClinicalPanel(
      padding: const EdgeInsets.all(14),
      radius: AppTheme.radiusSm,
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.muted(isDark),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.monoNumeral(
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.muted(isDark).withValues(alpha: 0.80),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SignalQualityLegend extends StatelessWidget {
  final bool compact;

  const SignalQualityLegend({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final children = [
      const ClinicalStatusPill(label: 'Good', color: AppTheme.signalGood),
      const ClinicalStatusPill(label: 'Fair', color: AppTheme.signalWarn),
      const ClinicalStatusPill(label: 'Bad', color: AppTheme.signalBad),
    ];

    if (compact) {
      return Wrap(spacing: 6, runSpacing: 6, children: children);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        children[0],
        const SizedBox(width: 6),
        children[1],
        const SizedBox(width: 6),
        children[2],
      ],
    );
  }
}

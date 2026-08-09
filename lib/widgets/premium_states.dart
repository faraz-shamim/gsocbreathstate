import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';

class PremiumLoadingState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final int rows;

  const PremiumLoadingState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.hourglass_top_rounded,
    this.rows = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.emerald : AppTheme.deepJade;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...List.generate(rows, (index) {
                final widthFactor = index.isEven ? 0.84 : 0.62;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == rows - 1 ? 0 : 12),
                  child: Row(
                    children: [
                      const _SkeletonBlock(width: 42, height: 42, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              widthFactor: widthFactor,
                              child: const _SkeletonBlock(height: 12),
                            ),
                            const SizedBox(height: 8),
                            const FractionallySizedBox(
                              widthFactor: 0.45,
                              child: _SkeletonBlock(height: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.emerald : AppTheme.deepJade;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: 18),
                  ScaleOnPress(
                    onTap: onActionPressed,
                    haptic: PressHaptic.light,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.24),
                            blurRadius: 18,
                            spreadRadius: -8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (actionIcon != null) ...[
                            Icon(
                              actionIcon,
                              color:
                                  isDark
                                      ? AppTheme.obsidian
                                      : AppTheme.pureWhite,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            actionLabel!,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color:
                                  isDark
                                      ? AppTheme.obsidian
                                      : AppTheme.pureWhite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBlock({this.width, required this.height, this.radius = 999});

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.42,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.72);

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(opacity: _opacity.value, child: child);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

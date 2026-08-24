// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:breath_state/services/hrv_analysis/hrv_psychophysiological_indices.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/metric_tile.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:breath_state/theme/app_theme.dart';

class PsychophysiologicalResultCard extends StatefulWidget {
  final PsychophysiologicalResult result;
  final bool expanded;

  const PsychophysiologicalResultCard({
    super.key,
    required this.result,
    this.expanded = false,
  });

  @override
  State<PsychophysiologicalResultCard> createState() =>
      _PsychophysiologicalResultCardState();
}

class _PsychophysiologicalResultCardState
    extends State<PsychophysiologicalResultCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppTheme.dustyRose,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Wellness Indices",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildBadge(isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildEssentialsGrid(context, isDark),
          if (_expanded) ...[
            const SizedBox(height: 20),
            ResultDivider(isDark: isDark),
            const SizedBox(height: 16),
            if (widget.result.warning != null) ...[
              _buildWarningRow(isDark),
              const SizedBox(height: 12),
            ],
            _buildExpandedMetrics(context, isDark),
            const SizedBox(height: 12),
            _buildFooter(isDark),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppTheme.emerald,
              ),
              label: Text(
                _expanded ? "Show less" : "Show all metrics",
                style: TextStyle(
                  color: AppTheme.emerald,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(bool isDark) {
    final score = widget.result.relaxationScore.value;

    final String label;
    final Color textColor;

    if (score != null) {
      label = '${score.toStringAsFixed(0)}/100';
      if (score >= 60) {
        textColor = AppTheme.emerald;
      } else if (score >= 35) {
        textColor = Colors.amber.shade700;
      } else {
        textColor = AppTheme.dustyRose;
      }
    } else {
      label = 'N/A';
      textColor = isDark ? Colors.white54 : Colors.black38;
    }

    return ResultBadge(
      text: label,
      color: textColor,
      isDark: isDark,
      icon: Icons.spa_rounded,
    );
  }

  Widget _buildEssentialsGrid(BuildContext context, bool isDark) {
    final essentials = widget.result.essentials();
    final entries = essentials.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = Responsive.metricTileWidth(constraints.maxWidth);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              entries.map((e) {
                return SizedBox(
                  width: tileW,
                  child: MetricTile(
                    label: e.key,
                    value: e.value,
                    isDark: isDark,
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildWarningRow(bool isDark) {
    return InsightBanner(
      text: widget.result.warning!,
      color: Colors.amber.shade700,
      isDark: isDark,
      icon: Icons.info_outline_rounded,
    );
  }

  PsychophysiologicalIndex? _indexForGroup(String groupName) {
    switch (groupName) {
      case 'Stress Assessment':
        return widget.result.stressIndex;
      case 'Autonomic Balance':
        return widget.result.autonomicBalance;
      case 'Parasympathetic Activity':
        return widget.result.parasympatheticTone;
      case 'Relaxation':
        return widget.result.relaxationScore;
      default:
        return null;
    }
  }

  Widget _buildExpandedMetrics(BuildContext context, bool isDark) {
    final groups = widget.result.allMetrics();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = Responsive.metricTileWidth(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              groups.entries.map((group) {
                final validMetrics =
                    group.value
                        .where((m) => m.value != null && m.value!.isFinite)
                        .toList();

                final coreIndex = _indexForGroup(group.key);

                if (validMetrics.isEmpty && coreIndex == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        group.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emerald.withValues(alpha: 0.8),
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (validMetrics.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children:
                            validMetrics.map((m) {
                              final formatted = _formatMetricValue(
                                m.value!,
                                m.unit,
                              );
                              return SizedBox(
                                width: tileW,
                                child: MetricTile(
                                  label: m.label,
                                  value: formatted,
                                  isDark: isDark,
                                  compact: true,
                                ),
                              );
                            }).toList(),
                      ),
                    if (coreIndex != null) ...[
                      const SizedBox(height: 8),
                      _buildInterpretationRow(coreIndex, isDark),
                    ],
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildInterpretationRow(PsychophysiologicalIndex index, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dotColor(index.level),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  index.interpretation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text(
              index.description,
              style: TextStyle(
                fontSize: 10,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.4,
                ),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColor(IndexLevel level) {
    switch (level) {
      case IndexLevel.low:
        return Colors.green;
      case IndexLevel.moderate:
        return Colors.amber;
      case IndexLevel.high:
      case IndexLevel.veryHigh:
        return Colors.red;
      case IndexLevel.unknown:
        return Colors.grey;
    }
  }

  String _formatMetricValue(double value, String unit) {
    final normalizedUnit = unit
        .replaceAll('\u00c2\u00b2', '^2')
        .replaceAll('\u00b2', '^2');
    switch (normalizedUnit) {
      case 'ms':
        return '${value.toStringAsFixed(1)} ms';
      case 'ms^2':
        return '${value.toStringAsFixed(1)} ms^2';
      case '%':
        return '${value.toStringAsFixed(0)}%';
      case 'BPM':
        return '${value.toStringAsFixed(1)} BPM';
      case '/100':
        return '${value.toStringAsFixed(0)}/100';
      case '':
        return value.toStringAsFixed(value < 10 ? 2 : 0);
      default:
        return '${value.toStringAsFixed(2)} $unit';
    }
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text(
        'Relaxation Score = 35% Stress + 25% Balance + 25% '
        'Parasympathetic + 15% Heart Rate. '
        'Based on Baevsky (2002), Shaffer & Ginsberg (2017).',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:breath_state/services/hrv_analysis/resonance_frequency_analyzer.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/metric_tile.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:breath_state/theme/app_theme.dart';

class ResonanceFrequencyResultCard extends StatefulWidget {
  final ResonanceFrequencyResult result;
  final bool expanded;

  const ResonanceFrequencyResultCard({
    super.key,
    required this.result,
    this.expanded = false,
  });

  @override
  State<ResonanceFrequencyResultCard> createState() =>
      _ResonanceFrequencyResultCardState();
}

class _ResonanceFrequencyResultCardState
    extends State<ResonanceFrequencyResultCard> {
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
              Icon(Icons.tune_rounded, color: AppTheme.emerald, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Resonance Frequency",
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
            _buildOptimalTrialMetrics(context, isDark),
            const SizedBox(height: 16),
            _buildTrialComparisonTable(context, isDark),
            const SizedBox(height: 16),
            _buildMethodComparison(context, isDark),
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
    final rate = widget.result.optimalBreathingRateBpm;
    final conf = widget.result.confidence;

    final Color badgeColor;
    if (conf >= 0.5) {
      badgeColor = AppTheme.emerald;
    } else if (conf >= 0.2) {
      badgeColor = Colors.amber.shade700;
    } else {
      badgeColor = isDark ? Colors.white54 : Colors.black38;
    }

    return ResultBadge(
      text: '${rate.toStringAsFixed(1)} BPM',
      color: badgeColor,
      isDark: isDark,
      icon: Icons.air_rounded,
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

  Widget _buildOptimalTrialMetrics(BuildContext context, bool isDark) {
    final groups = widget.result.allMetrics();
    final optimalMetrics = groups['Optimal Trial Metrics'];
    if (optimalMetrics == null || optimalMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final validMetrics =
        optimalMetrics
            .where((m) => m.value != null && m.value!.isFinite)
            .toList();
    if (validMetrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = Responsive.metricTileWidth(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                'Optimal Trial Metrics',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emerald.withValues(alpha: 0.8),
                  letterSpacing: 0,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children:
                  validMetrics.map((m) {
                    final formatted = _formatMetricValue(m.value!, m.unit);
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
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTrialComparisonTable(BuildContext context, bool isDark) {
    final comparisonData = widget.result.trialComparisonData();
    if (comparisonData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Trial Comparison',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.emerald.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 34,
                columnSpacing: 14,
                horizontalMargin: 10,
                headingRowColor: WidgetStateProperty.all(
                  (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                ),
                headingTextStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.6,
                  ),
                ),
                dataTextStyle: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                columns: const [
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Score'), numeric: true),
                  DataColumn(label: Text('RMSSD'), numeric: true),
                  DataColumn(label: Text('Align'), numeric: true),
                  DataColumn(label: Text('RSA'), numeric: true),
                  DataColumn(label: Text('Coher'), numeric: true),
                ],
                rows:
                    comparisonData.map((trial) {
                      final bool isOptimal = trial['isOptimal'] as bool;
                      final Color? rowColor =
                          isOptimal
                              ? AppTheme.emerald.withValues(
                                alpha: isDark ? 0.15 : 0.10,
                              )
                              : null;

                      return DataRow(
                        color:
                            rowColor != null
                                ? WidgetStateProperty.all(rowColor)
                                : null,
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOptimal)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 3),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: AppTheme.emerald,
                                    ),
                                  ),
                                Text(
                                  (trial['rateBpm'] as double).toStringAsFixed(
                                    1,
                                  ),
                                  style: TextStyle(
                                    fontWeight:
                                        isOptimal
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: isOptimal ? AppTheme.emerald : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              ((trial['compositeScore'] as double) * 100)
                                  .toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight:
                                    isOptimal
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(
                            Text((trial['rmssd'] as double).toStringAsFixed(1)),
                          ),
                          DataCell(
                            Text(
                              '${((trial['alignmentScore'] as double) * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${((trial['rsaScore'] as double) * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${((trial['coherence'] as double) * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodComparison(BuildContext context, bool isDark) {
    final r = widget.result;

    if (r.compositeAgreesWithRmssd) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.emerald.withValues(alpha: isDark ? 0.1 : 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: AppTheme.emerald,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Composite and RMSSD-only methods agree: '
                '${r.optimalBreathingRateBpm.toStringAsFixed(1)} BPM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.emerald,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 14,
                color: AppTheme.softSage,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Composite: ${r.optimalBreathingRateBpm.toStringAsFixed(1)} BPM  |  '
                  'RMSSD-only: ${r.rmssdOnlyOptimalBpm.toStringAsFixed(1)} BPM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.softSage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The composite method uses spectral analysis in addition to '
            'RMSSD, providing a more robust identification.',
            style: TextStyle(
              fontSize: 10,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.5,
              ),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetricValue(double value, String unit) {
    final normalizedUnit = unit
        .replaceAll('\u00c2\u00b2', '^2')
        .replaceAll('\u00b2', '^2');
    switch (normalizedUnit) {
      case 'BPM':
        return '${value.toStringAsFixed(1)} BPM';
      case '%':
        return '${value.toStringAsFixed(0)}%';
      case 'Hz':
        return '${value.toStringAsFixed(3)} Hz';
      case 'ms':
        return '${value.toStringAsFixed(1)} ms';
      case 'ms^2':
        return '${value.toStringAsFixed(1)} ms^2';
      case '/100':
        return '${value.toStringAsFixed(0)}/100';
      case '':
        return value.toStringAsFixed(0);
      default:
        return '${value.toStringAsFixed(2)} $unit';
    }
  }
}

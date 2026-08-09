import 'dart:math' as math;

import 'package:breath_state/services/psychometrics/psychometric_scales.dart';
import 'package:breath_state/services/psychometrics/scale_engine.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PsychometricTrendPoint {
  final DateTime timestamp;
  final PsychometricScaleType scaleType;
  final int score;
  final String severity;
  final bool requiresReview;

  const PsychometricTrendPoint({
    required this.timestamp,
    required this.scaleType,
    required this.score,
    required this.severity,
    required this.requiresReview,
  });
}

class HrvCoherenceTrendPoint {
  final DateTime timestamp;
  final double coherenceScore;

  const HrvCoherenceTrendPoint({
    required this.timestamp,
    required this.coherenceScore,
  });
}

class PsychometricTrendChart extends StatelessWidget {
  final PsychometricScaleType? scaleType;
  final int maxScaleScore;
  final List<PsychometricTrendPoint> psychometricPoints;
  final List<HrvCoherenceTrendPoint> hrvPoints;

  const PsychometricTrendChart({
    super.key,
    required this.scaleType,
    required this.maxScaleScore,
    required this.psychometricPoints,
    required this.hrvPoints,
  });

  @override
  Widget build(BuildContext context) {
    final points =
        psychometricPoints
            .where((point) => scaleType == null || point.scaleType == scaleType)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final hrv = List<HrvCoherenceTrendPoint>.from(hrvPoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (points.isEmpty && hrv.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'No trend data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    final allDates = [
      ...points.map((point) => point.timestamp),
      ...hrv.map((point) => point.timestamp),
    ]..sort();
    final minDate = allDates.first;
    final maxDate = allDates.last;
    final spanMs = math.max(1, maxDate.difference(minDate).inMilliseconds);
    final maxY = math.max(maxScaleScore.toDouble(), 1.0);

    double xOf(DateTime timestamp) {
      return timestamp.difference(minDate).inMilliseconds / spanMs;
    }

    final hrvSpots =
        hrv
            .map(
              (point) => FlSpot(
                xOf(point.timestamp),
                (point.coherenceScore.clamp(0, 100).toDouble() / 100.0) * maxY,
              ),
            )
            .toList();
    final psychSeries =
        PsychometricScaleType.values
            .map((type) {
              final typedPoints =
                  points.where((point) => point.scaleType == type).toList();
              final spots =
                  typedPoints
                      .map(
                        (point) => FlSpot(
                          xOf(point.timestamp),
                          point.score.toDouble(),
                        ),
                      )
                      .toList();
              return _ScaleSeries(
                type: type,
                points: typedPoints,
                spots: spots,
              );
            })
            .where((series) => series.spots.isNotEmpty)
            .toList();
    final hrvBarIndex = psychSeries.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.10);
    final labelColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: isDark ? 0.52 : 0.58);
    final sameDay =
        minDate.year == maxDate.year &&
        minDate.month == maxDate.month &&
        minDate.day == maxDate.day;
    final dateFormatter = DateFormat(sameDay ? 'h:mm a' : 'MMM d');
    final bottomTickValues = _bottomTickValues();
    final bottomTickLabels = _bottomTickLabels(
      bottomTickValues,
      minDate,
      spanMs,
      dateFormatter,
    );

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, maxY / 4),
            getDrawingHorizontalLine:
                (_) =>
                    FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: gridColor),
              bottom: BorderSide(color: gridColor),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: Text(
                'Coherence',
                style: TextStyle(color: labelColor, fontSize: 10),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: math.max(1, maxY / 4),
                getTitlesWidget: (value, _) {
                  final coherence = (value / maxY * 100).round();
                  return Text(
                    '$coherence',
                    style: TextStyle(color: labelColor, fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                scaleType?.displayName ?? 'Symptom score',
                style: TextStyle(color: labelColor, fontSize: 10),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: math.max(1, maxY / 4),
                getTitlesWidget:
                    (value, _) => Text(
                      value.round().toString(),
                      style: TextStyle(color: labelColor, fontSize: 10),
                    ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 0.25,
                getTitlesWidget: (value, _) {
                  final roundedValue = _nearestBottomTick(
                    value,
                    bottomTickValues,
                  );
                  if (roundedValue == null) return const SizedBox.shrink();
                  final label = bottomTickLabels[roundedValue];
                  if (label == null || label.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(color: labelColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final series in psychSeries) _scaleBar(series, isDark),
            if (hrvSpots.isNotEmpty)
              LineChartBarData(
                spots: hrvSpots,
                isCurved: true,
                curveSmoothness: 0.25,
                color: AppTheme.emerald,
                barWidth: 3,
                dashArray: [8, 5],
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter:
                      (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.emerald,
                        strokeWidth: 2,
                        strokeColor: isDark ? AppTheme.obsidian : Colors.white,
                      ),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 10,
              getTooltipColor:
                  (_) => isDark ? AppTheme.charcoal : AppTheme.pureWhite,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  if (spot.barIndex < psychSeries.length) {
                    final series = psychSeries[spot.barIndex];
                    final point = series.points[spot.spotIndex];
                    final maxScore =
                        definitionForScale(point.scaleType).maxScore;
                    return LineTooltipItem(
                      '${point.scaleType.displayName} ${point.score}/$maxScore\n${point.severity}',
                      TextStyle(
                        color: scaleColor(point.scaleType),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }
                  if (spot.barIndex != hrvBarIndex) return null;
                  final point = hrv[spot.spotIndex];
                  return LineTooltipItem(
                    'Coherence ${point.coherenceScore.toStringAsFixed(0)}',
                    const TextStyle(
                      color: AppTheme.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _scaleBar(_ScaleSeries series, bool isDark) {
    final color = scaleColor(series.type);
    return LineChartBarData(
      spots: series.spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, index) {
          final point = series.points[index];
          return FlDotCirclePainter(
            radius: point.requiresReview ? 5 : 4,
            color: color,
            strokeWidth: 2,
            strokeColor: isDark ? AppTheme.obsidian : Colors.white,
          );
        },
      ),
    );
  }

  List<double> _bottomTickValues() {
    return const [0.0, 0.25, 0.5, 0.75, 1.0];
  }

  Map<double, String> _bottomTickLabels(
    List<double> ticks,
    DateTime minDate,
    int spanMs,
    DateFormat formatter,
  ) {
    final seen = <String>{};
    return {
      for (final value in ticks)
        value: () {
          final label = formatter.format(
            minDate.add(Duration(milliseconds: (spanMs * value).round())),
          );
          if (!seen.add(label)) return '';
          return label;
        }(),
    };
  }

  double? _nearestBottomTick(double value, List<double> ticks) {
    for (final tick in ticks) {
      if ((value - tick).abs() < 0.02) return tick;
    }
    return null;
  }
}

class _ScaleSeries {
  final PsychometricScaleType type;
  final List<PsychometricTrendPoint> points;
  final List<FlSpot> spots;

  const _ScaleSeries({
    required this.type,
    required this.points,
    required this.spots,
  });
}

Color scaleColor(PsychometricScaleType type) {
  switch (type) {
    case PsychometricScaleType.phq9:
      return AppTheme.clinicalCyan;
    case PsychometricScaleType.gad7:
      return AppTheme.signalWarn;
    case PsychometricScaleType.pcl5:
      return AppTheme.cardiacRose;
  }
}

Color psychometricScoreColor(
  PsychometricScaleType type,
  int score,
  bool requiresReview,
) {
  if (requiresReview) return AppTheme.signalBad;
  final maxScore = definitionForScale(type).maxScore;
  final ratio = maxScore <= 0 ? 0.0 : score / maxScore;
  if (ratio >= 0.70) return AppTheme.signalBad;
  if (ratio >= 0.45) return AppTheme.signalWarn;
  if (ratio >= 0.22) return AppTheme.cardiacRose;
  return AppTheme.signalGood;
}

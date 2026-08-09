                                                                    
library;

import 'dart:math' as math;

import 'package:breath_state/services/biofeedback/signal_quality_index.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/clinical_primitives.dart';
import 'package:flutter/material.dart';

class DualWaveformChart extends StatelessWidget {
                                     
  final List<double> rrIntervals;

                                         
  final List<SqiResult> sqiResults;

                                                           
  final List<double> respirationValues;

                                  
  final double height;

  const DualWaveformChart({
    super.key,
    required this.rrIntervals,
    required this.sqiResults,
    this.respirationValues = const [],
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = rrIntervals.length >= 2 || respirationValues.length >= 2;
    final sqiSummary = _summarizeSqi();

    return ClinicalPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      radius: AppTheme.radiusLg,
      tint: AppTheme.clinicalTeal,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RR + respiration',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Live window, normalized to the last minute',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ClinicalStatusPill(
                  label: sqiSummary.label,
                  color: sqiSummary.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: hasData
                  ? CustomPaint(
                      painter: _DualWaveformPainter(
                        rrIntervals: rrIntervals,
                        sqiResults: sqiResults,
                        respirationValues: respirationValues,
                        isDark: isDark,
                      ),
                      size: Size.infinite,
                    )
                  : _EmptyWaveformState(isDark: isDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: const [
                ClinicalStatusPill(label: 'RR ms', color: AppTheme.cardiacRose),
                ClinicalStatusPill(
                  label: 'Resp a.u.',
                  color: AppTheme.clinicalTeal,
                ),
                ClinicalStatusPill(
                  label: 'SQI bands',
                  color: AppTheme.signalWarn,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _SqiSummary _summarizeSqi() {
    if (sqiResults.isEmpty) {
      return const _SqiSummary('SQI pending', AppTheme.clinicalCyan);
    }
    final bad = sqiResults.where((s) => s.level == SqiLevel.bad).length;
    final warn = sqiResults.where((s) => s.level == SqiLevel.warning).length;
    final total = sqiResults.length;
    if (bad / total > 0.18) {
      return const _SqiSummary('Bad SQI', AppTheme.signalBad);
    }
    if ((bad + warn) / total > 0.24) {
      return const _SqiSummary('Fair SQI', AppTheme.signalWarn);
    }
    return const _SqiSummary('Good SQI', AppTheme.signalGood);
  }
}

class _SqiSummary {
  final String label;
  final Color color;

  const _SqiSummary(this.label, this.color);
}

class _EmptyWaveformState extends StatelessWidget {
  final bool isDark;

  const _EmptyWaveformState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 28,
            color: AppTheme.muted(isDark).withValues(alpha: 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for live samples',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted(isDark)),
          ),
        ],
      ),
    );
  }
}

class _DualWaveformPainter extends CustomPainter {
  final List<double> rrIntervals;
  final List<SqiResult> sqiResults;
  final List<double> respirationValues;
  final bool isDark;

  _DualWaveformPainter({
    required this.rrIntervals,
    required this.sqiResults,
    required this.respirationValues,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 42.0;
    final right = 8.0;
    final top = 8.0;
    final bottom = 20.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      math.max(1, size.width - left - right),
      math.max(1, size.height - top - bottom),
    );
    final hasResp = respirationValues.length >= 2;
    final rrRect = hasResp
        ? Rect.fromLTWH(chart.left, chart.top, chart.width, chart.height * 0.56)
        : chart;
    final respRect = Rect.fromLTWH(
      chart.left,
      rrRect.bottom + 16,
      chart.width,
      hasResp ? chart.bottom - rrRect.bottom - 16 : 0,
    );

    _drawGrid(canvas, rrRect, yDivisions: 3);
    if (hasResp) _drawGrid(canvas, respRect, yDivisions: 2);
    _drawSqiBands(canvas, rrRect);
    _drawRr(canvas, rrRect);
    if (hasResp) _drawRespiration(canvas, respRect);
    _drawCursor(canvas, chart);
    _drawAxisLabels(canvas, rrRect, respRect, hasResp);
  }

  void _drawGrid(Canvas canvas, Rect rect, {required int yDivisions}) {
    final paint = Paint()
      ..color = AppTheme.gridline(isDark)
      ..strokeWidth = 1;

    for (var i = 0; i <= yDivisions; i++) {
      final y = rect.top + rect.height * i / yDivisions;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawSqiBands(Canvas canvas, Rect rect) {
    if (sqiResults.isEmpty) return;
    final count = math.max(rrIntervals.length, sqiResults.length);
    if (count < 2) return;
    final step = rect.width / (count - 1);
    for (var i = 0; i < sqiResults.length; i++) {
      final level = sqiResults[i].level;
      if (level == SqiLevel.good) continue;
      final color = level == SqiLevel.warning
          ? AppTheme.signalWarn
          : AppTheme.signalBad;
      final x = rect.left + i * step;
      final bandLeft = math.max(
        rect.left,
        math.min(x - step * 0.46, rect.right),
      );
      final band = Rect.fromLTWH(
        bandLeft,
        rect.top,
        math.max(2, step * 0.92),
        rect.height,
      );
      canvas.drawRect(
        band,
        Paint()..color = color.withValues(alpha: isDark ? 0.12 : 0.10),
      );
    }
  }

  void _drawRr(Canvas canvas, Rect rect) {
    if (rrIntervals.length < 2) return;
    final minMax = _expandedRange(rrIntervals, padFraction: 0.12, minPad: 24);
    final minV = minMax.$1;
    final maxV = minMax.$2;
    Offset map(int i, double v) {
      final x = rect.left + rect.width * i / (rrIntervals.length - 1);
      final y = rect.bottom - ((v - minV) / (maxV - minV)) * rect.height;
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(map(0, rrIntervals[0]).dx, map(0, rrIntervals[0]).dy);
    for (var i = 1; i < rrIntervals.length; i++) {
      final p = map(i, rrIntervals[i]);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppTheme.cardiacRose,
    );

    final latest = map(rrIntervals.length - 1, rrIntervals.last);
    canvas.drawCircle(
      latest,
      4,
      Paint()..color = isDark ? AppTheme.graphite : AppTheme.pureWhite,
    );
    canvas.drawCircle(latest, 3, Paint()..color = AppTheme.cardiacRose);

    _drawText(canvas, '${maxV.round()}', Offset(2, rect.top - 5));
    _drawText(canvas, '${minV.round()}', Offset(2, rect.bottom - 10));
    _drawText(canvas, 'RR ms', Offset(2, rect.center.dy - 5));
  }

  void _drawRespiration(Canvas canvas, Rect rect) {
    final values = respirationValues;
    if (values.length < 2) return;
    final minMax = _expandedRange(values, padFraction: 0.10, minPad: 0.1);
    final minV = minMax.$1;
    final maxV = minMax.$2;

    Offset map(int i, double v) {
      final x = rect.left + rect.width * i / (values.length - 1);
      final y = rect.bottom - ((v - minV) / (maxV - minV)) * rect.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(map(0, values[0]).dx, map(0, values[0]).dy);
    for (var i = 1; i < values.length; i++) {
      final p = map(i, values[i]);
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.clinicalTeal.withValues(alpha: isDark ? 0.12 : 0.10),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppTheme.clinicalTeal,
    );
    _drawText(canvas, 'Resp a.u.', Offset(2, rect.center.dy - 5));
  }

  void _drawCursor(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppTheme.foreground(isDark).withValues(alpha: 0.22)
      ..strokeWidth = 1;
    final x = rect.right;
    const dash = 4.0;
    var y = rect.top;
    while (y < rect.bottom) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, rect.bottom)),
        paint,
      );
      y += dash * 2;
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    Rect rrRect,
    Rect respRect,
    bool hasResp,
  ) {
    final bottomY = hasResp ? respRect.bottom + 6 : rrRect.bottom + 6;
    _drawText(canvas, '-60s', Offset(rrRect.left, bottomY));
    _drawText(canvas, 'now', Offset(rrRect.right - 18, bottomY));
  }

  (double, double) _expandedRange(
    List<double> values, {
    required double padFraction,
    required double minPad,
  }) {
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    final range = maxV - minV;
    final pad = math.max(range * padFraction, minPad);
    minV -= pad;
    maxV += pad;
    if ((maxV - minV).abs() < 0.0001) {
      maxV += 1;
      minV -= 1;
    }
    return (minV, maxV);
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppTheme.muted(isDark).withValues(alpha: 0.78),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DualWaveformPainter oldDelegate) => true;
}

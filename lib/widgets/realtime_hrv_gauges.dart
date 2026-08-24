// SPDX-License-Identifier: AGPL-3.0-only
                                                     
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/clinical_primitives.dart';
import 'package:flutter/material.dart';

class RealtimeHrvGauges extends StatefulWidget {
  final Stream<RealtimeHrvSnapshot> snapshotStream;

  const RealtimeHrvGauges({super.key, required this.snapshotStream});

  @override
  State<RealtimeHrvGauges> createState() => _RealtimeHrvGaugesState();
}

class _RealtimeHrvGaugesState extends State<RealtimeHrvGauges> {
  RealtimeHrvSnapshot? _latest;
  final List<double> _coherenceHistory = [];
  static const int _maxHistory = 60;
  StreamSubscription<RealtimeHrvSnapshot>? _snapshotSub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant RealtimeHrvGauges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshotStream != widget.snapshotStream) {
      _snapshotSub?.cancel();
      _listen();
    }
  }

  void _listen() {
    _snapshotSub = widget.snapshotStream.listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _latest = snapshot;
        _coherenceHistory.add(snapshot.coherence);
        if (_coherenceHistory.length > _maxHistory) {
          _coherenceHistory.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snapshot = _latest;

    return ClinicalPanel(
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusLg,
      tint: AppTheme.cardiacRose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClinicalSectionHeader(
            eyebrow: 'Live HRV',
            title: 'Coherence and recovery load',
            trailing: snapshot == null
                ? const ClinicalStatusPill(
                    label: 'Waiting',
                    color: AppTheme.clinicalCyan,
                  )
                : ClinicalStatusPill(
                    label:
                        '${snapshot.windowDurationSec.toStringAsFixed(0)}s window',
                    color: _coherenceColor(snapshot.coherence),
                  ),
          ),
          const SizedBox(height: 16),
          if (snapshot == null)
            SizedBox(
              height: 132,
              child: Center(
                child: Text(
                  'Waiting for clean RR intervals',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted(isDark),
                  ),
                ),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 340;
                final gauge = _CoherenceGauge(snapshot: snapshot);
                final metrics = _MetricGrid(snapshot: snapshot);
                if (narrow) {
                  return Column(
                    children: [gauge, const SizedBox(height: 14), metrics],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 132, child: gauge),
                    const SizedBox(width: 14),
                    Expanded(child: metrics),
                  ],
                );
              },
            ),
            if (_coherenceHistory.length >= 2) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Coherence trend',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted(isDark),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '0-100',
                    style: AppTheme.monoNumeral(
                      color: AppTheme.muted(isDark),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: _coherenceHistory,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _coherenceColor(double value) {
    if (value >= 70) return AppTheme.signalGood;
    if (value >= 40) return AppTheme.signalWarn;
    return AppTheme.signalBad;
  }
}

class _CoherenceGauge extends StatelessWidget {
  final RealtimeHrvSnapshot snapshot;

  const _CoherenceGauge({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final value = snapshot.coherence.clamp(0, 100).toDouble();
    final color = value >= 70
        ? AppTheme.signalGood
        : value >= 40
        ? AppTheme.signalWarn
        : AppTheme.signalBad;
    final interpretation = value >= 70
        ? 'stable, rising'
        : value >= 40
        ? 'review signal'
        : 'low confidence';

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _CoherenceGaugePainter(value: value / 100, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.round().toString(),
                style: AppTheme.monoNumeral(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('Coherence', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 3),
              Text(
                interpretation,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final RealtimeHrvSnapshot snapshot;

  const _MetricGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final rmssd = snapshot.timeDomain?.rmssd;
    final sdnn = snapshot.timeDomain?.sdnn;
    final peak = snapshot.coherencePeakFrequencyHz;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.34,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ClinicalMetricTile(
          label: 'HR',
          value: snapshot.instantHR.round().toString(),
          unit: 'bpm',
          caption: 'latest RR',
          color: AppTheme.cardiacRose,
        ),
        ClinicalMetricTile(
          label: 'RMSSD',
          value: rmssd == null ? '--' : rmssd.toStringAsFixed(0),
          unit: 'ms',
          caption: 'rolling window',
          color: AppTheme.clinicalTeal,
        ),
        ClinicalMetricTile(
          label: 'SDNN',
          value: sdnn == null ? '--' : sdnn.toStringAsFixed(0),
          unit: 'ms',
          caption: 'accepted RR',
          color: AppTheme.clinicalCyan,
        ),
        ClinicalMetricTile(
          label: 'Peak',
          value: peak == null ? '--' : peak.toStringAsFixed(3),
          unit: 'Hz',
          caption: 'LF coherence',
          color: AppTheme.signalGood,
        ),
      ],
    );
  }
}

class _CoherenceGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _CoherenceGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const startAngle = math.pi * 0.76;
    const sweepMax = math.pi * 1.48;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      bgPaint,
    );

    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax * value.clamp(0, 1),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_CoherenceGaugePainter old) =>
      old.value != value || old.color != color;
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final bool isDark;

  _SparklinePainter({required this.values, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = AppTheme.gridline(isDark)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i].clamp(0, 100) / 100) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final latest = values.last;
    final lineColor = latest >= 70
        ? AppTheme.signalGood
        : latest >= 40
        ? AppTheme.signalWarn
        : AppTheme.signalBad;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => true;
}

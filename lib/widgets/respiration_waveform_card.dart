// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:math' as math;
import 'package:breath_state/services/breath_rate/belt_breath_rate.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:flutter/material.dart';

class RespirationWaveformCard extends StatefulWidget {
  final Stream<double> forceStream;
  final double sampleRateHz;
  final int windowSeconds;

  const RespirationWaveformCard({
    super.key,
    required this.forceStream,
    this.sampleRateHz = 10.0,
    this.windowSeconds = 15,
  });

  @override
  State<RespirationWaveformCard> createState() =>
      _RespirationWaveformCardState();
}

class _RespirationWaveformCardState extends State<RespirationWaveformCard> {
  final List<double> _buffer = [];
  late final int _maxSamples;
  StreamSubscription<double>? _sub;
  double _currentBpm = 0;
  List<int> _peakIndices = [];

  @override
  void initState() {
    super.initState();
    _maxSamples = (widget.sampleRateHz * widget.windowSeconds).round();
    _sub = widget.forceStream.listen(_onSample);
  }

  void _onSample(double value) {
    _buffer.add(value);
    if (_buffer.length > _maxSamples) {
      _buffer.removeRange(0, _buffer.length - _maxSamples);
    }

    if (_buffer.length % widget.sampleRateHz.round() == 0 &&
        _buffer.length >= widget.sampleRateHz.round() * 3) {
      final result = estimateBreathRateFromForce(
        _buffer,
        sampleRateHz: widget.sampleRateHz,
      );
      _currentBpm = result.bpm;
      _peakIndices = result.peakIndices;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.air_rounded,
                color: AppTheme.emerald.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Respiration Waveform',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (_currentBpm > 0)
                ResultBadge(
                  text: '${_currentBpm.toStringAsFixed(1)} bpm',
                  color: AppTheme.emerald,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2.8,
            child:
                _buffer.length < 2
                    ? Center(
                      child: Text(
                        'Waiting for data...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                    : CustomPaint(
                      painter: _WaveformPainter(
                        data: List.unmodifiable(_buffer),
                        peakIndices: _peakIndices,
                        lineColor: AppTheme.emerald,
                        peakColor: AppTheme.dustyRose,
                        bgLineColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.06),
                      ),
                      size: Size.infinite,
                    ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final List<int> peakIndices;
  final Color lineColor;
  final Color peakColor;
  final Color bgLineColor;

  _WaveformPainter({
    required this.data,
    required this.peakIndices,
    required this.lineColor,
    required this.peakColor,
    required this.bgLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    double minVal = data.reduce(math.min);
    double maxVal = data.reduce(math.max);
    final range = maxVal - minVal;
    if (range < 0.001) {
      minVal -= 0.5;
      maxVal += 0.5;
    } else {
      minVal -= range * 0.1;
      maxVal += range * 0.1;
    }

    double mapY(double v) =>
        size.height - ((v - minVal) / (maxVal - minVal)) * size.height;

    final xStep = size.width / (data.length - 1);

    final bgPaint =
        Paint()
          ..color = bgLineColor
          ..strokeWidth = 1;
    final midY = mapY((minVal + maxVal) / 2);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), bgPaint);

    final linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, mapY(data[0]));
    for (int i = 1; i < data.length; i++) {
      path.lineTo(i * xStep, mapY(data[i]));
    }
    canvas.drawPath(path, linePaint);

    final fillPath =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.25),
              lineColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final peakPaint = Paint()..color = peakColor;
    for (final idx in peakIndices) {
      if (idx >= 0 && idx < data.length) {
        canvas.drawCircle(Offset(idx * xStep, mapY(data[idx])), 4, peakPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}

import 'dart:math' as math;
import 'package:breath_state/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:breath_state/services/hrv_analysis/hrv_frequency_domain.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/metric_tile.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:breath_state/theme/app_theme.dart';

class HrvFrequencyResultCard extends StatefulWidget {
  final HrvFrequencyDomainResult result;
  final bool expanded;

  const HrvFrequencyResultCard({
    super.key,
    required this.result,
    this.expanded = false,
  });

  @override
  State<HrvFrequencyResultCard> createState() => _HrvFrequencyResultCardState();
}

class _HrvFrequencyResultCardState extends State<HrvFrequencyResultCard> {
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
                Icons.stacked_line_chart_rounded,
                color: AppTheme.dustyRose,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "HRV Frequency Analysis",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildBadge(isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildEssentialsGrid(context, isDark),
          if (_expanded) ...[
            const SizedBox(height: 20),
            ResultDivider(isDark: isDark),
            const SizedBox(height: 16),
            _buildExpandedMetrics(context, isDark),
            const SizedBox(height: 16),
            if (widget.result.durationWarning != null) ...[
              _buildWarningRow(isDark),
              const SizedBox(height: 12),
            ],
            _buildPsdPlot(isDark),
            const SizedBox(height: 12),
            Text(
              "",
              style: TextStyle(
                fontSize: 10,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.4,
                ),
                fontStyle: FontStyle.italic,
              ),
            ),
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
    final r = widget.result;
    final badgeText =
        r.lfHfRatio.isFinite ? r.lfHfRatio.toStringAsFixed(2) : 'N/A';
    return ResultBadge(
      text: 'LF/HF $badgeText',
      color: AppTheme.dustyRose,
      isDark: isDark,
      icon: Icons.show_chart_rounded,
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
                Color? accent;
                if (e.key.contains('LF')) {
                  accent = AppTheme.emerald;
                } else if (e.key.contains('HF')) {
                  accent = AppTheme.dustyRose;
                }
                return SizedBox(
                  width: tileW,
                  child: MetricTile(
                    label: e.key,
                    value: e.value,
                    isDark: isDark,
                    accentColor: accent,
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildWarningRow(bool isDark) {
    return InsightBanner(
      text: widget.result.durationWarning!,
      color: Colors.amber.shade700,
      isDark: isDark,
      icon: Icons.warning_amber_rounded,
    );
  }

  Widget _buildExpandedMetrics(BuildContext context, bool isDark) {
    final groups = widget.result.allBandMetrics();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW = Responsive.metricTileWidth(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              groups.entries.map((group) {
                final validMetrics =
                    group.value.where((m) {
                      return m.value != null &&
                          m.value != double.negativeInfinity;
                    }).toList();

                if (validMetrics.isEmpty) return const SizedBox.shrink();

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
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
        );
      },
    );
  }

  String _formatMetricValue(double value, String unit) {
    final normalizedUnit = unit
        .replaceAll('\u00c2\u00b2', '^2')
        .replaceAll('\u00b2', '^2');
    switch (normalizedUnit) {
      case 'ms^2':
        return '${value.toStringAsFixed(1)} ms^2';
      case 'Hz':
        return '${value.toStringAsFixed(3)} Hz';
      case '%':
        return '${value.toStringAsFixed(1)}%';
      case 'n.u.':
        return '${value.toStringAsFixed(1)} n.u.';
      case 'ln(ms^2)':
        return '${value.toStringAsFixed(3)} ln(ms^2)';
      default:
        return value.toStringAsFixed(3);
    }
  }

  Widget _buildPsdPlot(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "PSD Spectrum",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.emerald.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _PsdPlotPainter(
              frequencies: widget.result.frequencies,
              psd: widget.result.psd,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}

                                                                                                                                                               

class _PsdPlotPainter extends CustomPainter {
  final List<double> frequencies;
  final List<double> psd;
  final bool isDark;

  _PsdPlotPainter({
    required this.frequencies,
    required this.psd,
    required this.isDark,
  });

  static const double _xMin = 0.0;
  static const double _xMax = 0.5;
  static const double _lfLow = 0.04;
  static const double _lfHigh = 0.15;
  static const double _hfLow = 0.15;
  static const double _hfHigh = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    if (frequencies.isEmpty || psd.isEmpty) return;

    const double leftMargin = 40;
    const double bottomMargin = 24;
    const double topMargin = 8;
    const double rightMargin = 8;

    final plotWidth = size.width - leftMargin - rightMargin;
    final plotHeight = size.height - topMargin - bottomMargin;

    double yMax = 0;
    for (int i = 0; i < frequencies.length; i++) {
      if (frequencies[i] >= _xMin &&
          frequencies[i] <= _xMax &&
          psd[i].isFinite) {
        yMax = math.max(yMax, psd[i]);
      }
    }
    if (yMax <= 0) yMax = 1;
    yMax *= 1.1;

    double xToPixel(double freq) =>
        leftMargin + (freq - _xMin) / (_xMax - _xMin) * plotWidth;
    double yToPixel(double power) =>
        topMargin + plotHeight - (power / yMax) * plotHeight;

    _drawBandFill(
      canvas,
      xToPixel,
      yToPixel,
      _lfLow,
      _lfHigh,
      AppTheme.emerald.withValues(alpha: 0.2),
      plotHeight + topMargin,
    );
    _drawBandFill(
      canvas,
      xToPixel,
      yToPixel,
      _hfLow,
      _hfHigh,
      AppTheme.dustyRose.withValues(alpha: 0.2),
      plotHeight + topMargin,
    );

    final gridPaint =
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.15,
          )
          ..strokeWidth = 0.8;

    for (final boundary in [_lfLow, _lfHigh, _hfHigh]) {
      final x = xToPixel(boundary);
      _drawDashedLine(
        canvas,
        Offset(x, topMargin),
        Offset(x, topMargin + plotHeight),
        gridPaint,
      );
    }

    final linePaint =
        Paint()
          ..color = isDark ? Colors.white : Colors.black87
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    bool started = false;
    for (int i = 0; i < frequencies.length; i++) {
      if (frequencies[i] < _xMin || frequencies[i] > _xMax) continue;
      if (!psd[i].isFinite) continue;
      final px = xToPixel(frequencies[i]);
      final py = yToPixel(psd[i]);
      if (!started) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, linePaint);

    final labelStyle = TextStyle(
      fontSize: 9,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
    );

    _drawText(
      canvas,
      "0",
      Offset(xToPixel(0) - 4, topMargin + plotHeight + 4),
      labelStyle,
    );
    _drawText(
      canvas,
      "0.15",
      Offset(xToPixel(0.15) - 10, topMargin + plotHeight + 4),
      labelStyle,
    );
    _drawText(
      canvas,
      "0.4",
      Offset(xToPixel(0.4) - 8, topMargin + plotHeight + 4),
      labelStyle,
    );

    _drawVerticalText(
      canvas,
      "PSD (ms^2/Hz)",
      Offset(2, topMargin + plotHeight / 2),
      TextStyle(
        fontSize: 8,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
      ),
    );
  }

  void _drawBandFill(
    Canvas canvas,
    double Function(double) xToPixel,
    double Function(double) yToPixel,
    double fLow,
    double fHigh,
    Color color,
    double baseline,
  ) {
    final fillPath = Path();
    fillPath.moveTo(xToPixel(fLow), baseline);

    bool hasPoints = false;
    for (int i = 0; i < frequencies.length; i++) {
      if (frequencies[i] >= fLow &&
          frequencies[i] <= fHigh &&
          psd[i].isFinite) {
        fillPath.lineTo(xToPixel(frequencies[i]), yToPixel(psd[i]));
        hasPoints = true;
      }
    }

    if (!hasPoints) return;

    fillPath.lineTo(xToPixel(fHigh), baseline);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = color);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final ux = dx / distance;
    final uy = dy / distance;

    double drawn = 0;
    while (drawn < distance) {
      final segEnd = math.min(drawn + dashLength, distance);
      canvas.drawLine(
        Offset(start.dx + ux * drawn, start.dy + uy * drawn),
        Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
        paint,
      );
      drawn += dashLength + gapLength;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawVerticalText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(-math.pi / 2);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PsdPlotPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

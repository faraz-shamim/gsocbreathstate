// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:math' as math;
import 'package:breath_state/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:breath_state/services/hrv_analysis/hrv_rsa.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/metric_tile.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:breath_state/theme/app_theme.dart';

class HrvRsaResultCard extends StatefulWidget {
  final HrvRsaResult result;
  final bool expanded;

  const HrvRsaResultCard({
    super.key,
    required this.result,
    this.expanded = false,
  });

  @override
  State<HrvRsaResultCard> createState() => _HrvRsaResultCardState();
}

class _HrvRsaResultCardState extends State<HrvRsaResultCard> {
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
              Icon(Icons.waves_rounded, color: AppTheme.dustyRose, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "RSA & Breathing Analysis",
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
            if (widget.result.hrvDerivedBreathRateBpm != null &&
                widget.result.hrvDerivedBreathRateBpm! > 0 &&
                widget.result.respiratoryBreathRateBpm != null) ...[
              const SizedBox(height: 8),
              _buildComparisonRow(isDark),
            ],
            if (widget.result.hrvBreathingDetail != null &&
                widget.result.hrvBreathingDetail!.frequencies.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSpectrumPlot(isDark),
            ],
            if (widget.result.p2tValues.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildP2TChart(isDark),
            ],
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
    final rate = widget.result.hrvDerivedBreathRateBpm;
    final conf = widget.result.hrvBreathRateConfidence;

    final String label;
    final Color textColor;

    if (rate != null && rate > 0) {
      label = '${rate.toStringAsFixed(1)} BPM';
      textColor =
          (conf != null && conf >= 0.5)
              ? AppTheme.emerald
              : (conf != null && conf >= 0.2
                  ? Colors.amber.shade700
                  : (isDark ? Colors.white70 : Colors.black54));
    } else {
      label = 'N/A';
      textColor = isDark ? Colors.white54 : Colors.black38;
    }

    return ResultBadge(
      text: label,
      color: textColor,
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
      case 'BPM':
        return '${value.toStringAsFixed(1)} BPM';
      case '%':
        return '${value.toStringAsFixed(0)}%';
      case 'Hz':
        return '${value.toStringAsFixed(3)} Hz';
      case 'ms':
        return '${value.toStringAsFixed(1)} ms';
      case 'ln(ms)':
        return '${value.toStringAsFixed(3)} ln(ms)';
      case 'ln(ms^2)':
        return '${value.toStringAsFixed(3)} ln(ms^2)';
      case 'ln(ln(ms^2))':
        return '${value.toStringAsFixed(3)} ln(ln(ms^2))';
      case '':
        return value.toStringAsFixed(0);
      default:
        return '${value.toStringAsFixed(2)} $unit';
    }
  }

  Widget _buildComparisonRow(bool isDark) {
    final hrv = widget.result.hrvDerivedBreathRateBpm!;
    final sig = widget.result.respiratoryBreathRateBpm!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded, size: 14, color: AppTheme.emerald),
          const SizedBox(width: 6),
          Text(
            'HRV: ${hrv.toStringAsFixed(1)} BPM  |  Signal: ${sig.toStringAsFixed(1)} BPM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.emerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumPlot(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'HRV Breathing Spectrum',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.emerald.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _SpectrumPlotPainter(
              detail: widget.result.hrvBreathingDetail!,
              peakHz: widget.result.hrvBreathRatePeakHz,
              peakBpm: widget.result.hrvDerivedBreathRateBpm,
              tealColor: AppTheme.emerald,
              accentColor: AppTheme.dustyRose,
              textColor: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.5,
              ),
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildP2TChart(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Per-Cycle RSA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.emerald.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _P2TBarChartPainter(
              values: widget.result.p2tValues,
              meanValue: widget.result.p2tMean,
              barColor: AppTheme.emerald,
              meanLineColor: AppTheme.dustyRose,
              textColor: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text(
        'P2T: Lewis et al. (2012) - PB: Porges & Bohrer (1990)',
        style: TextStyle(
          fontSize: 9,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _SpectrumPlotPainter extends CustomPainter {
  final dynamic detail;
  final double? peakHz;
  final double? peakBpm;
  final Color tealColor;
  final Color accentColor;
  final Color textColor;
  final bool isDark;

  _SpectrumPlotPainter({
    required this.detail,
    required this.peakHz,
    required this.peakBpm,
    required this.tealColor,
    required this.accentColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> freqs = detail.frequencies;
    final List<double> psd = detail.psd;
    if (freqs.isEmpty || psd.isEmpty) return;

    const double leftPad = 8;
    const double bottomPad = 18;
    const double topPad = 14;
    const double rightPad = 8;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    const double xMin = 0.0;
    const double xMax = 0.5;

    double yMax = 0;
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= xMin && freqs[i] <= xMax && psd[i] > yMax) {
        yMax = psd[i];
      }
    }
    if (yMax <= 0) yMax = 1;
    yMax *= 1.1;

    double xToPixel(double f) =>
        leftPad + ((f - xMin) / (xMax - xMin)) * chartW;
    double yToPixel(double p) => topPad + chartH - (p / yMax) * chartH;

    final bandRect = Rect.fromLTRB(
      xToPixel(0.15),
      topPad,
      xToPixel(0.40),
      topPad + chartH,
    );
    canvas.drawRect(
      bandRect,
      Paint()..color = tealColor.withValues(alpha: 0.15),
    );

    final path = Path();
    bool started = false;
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] < xMin || freqs[i] > xMax) continue;
      final px = xToPixel(freqs[i]);
      final py = yToPixel(psd[i].clamp(0, yMax));
      if (!started) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = tealColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    if (peakHz != null && peakHz! >= xMin && peakHz! <= xMax) {
      final px = xToPixel(peakHz!);

      final dashPaint =
          Paint()
            ..color = accentColor.withValues(alpha: 0.6)
            ..strokeWidth = 1.0;
      const dashLen = 3.0;
      const gapLen = 3.0;
      double y = topPad;
      while (y < topPad + chartH) {
        canvas.drawLine(
          Offset(px, y),
          Offset(px, math.min(y + dashLen, topPad + chartH)),
          dashPaint,
        );
        y += dashLen + gapLen;
      }

      double peakPsd = 0;
      for (int i = 0; i < freqs.length; i++) {
        if ((freqs[i] - peakHz!).abs() < 0.005 && psd[i] > peakPsd) {
          peakPsd = psd[i];
        }
      }
      final dotY = yToPixel(peakPsd.clamp(0, yMax));
      canvas.drawCircle(Offset(px, dotY), 4, Paint()..color = accentColor);

      if (peakBpm != null && peakBpm! > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${peakBpm!.toStringAsFixed(1)} BPM',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX =
            (px + 6 + tp.width > size.width - rightPad)
                ? px - tp.width - 6
                : px + 6;
        tp.paint(canvas, Offset(labelX, dotY - tp.height - 2));
      }
    }

    final xLabel = TextPainter(
      text: TextSpan(
        text: 'Frequency (Hz)',
        style: TextStyle(fontSize: 8, color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(
      canvas,
      Offset(leftPad + chartW / 2 - xLabel.width / 2, size.height - 4),
    );
  }

  @override
  bool shouldRepaint(covariant _SpectrumPlotPainter old) =>
      old.peakHz != peakHz;
}

class _P2TBarChartPainter extends CustomPainter {
  final List<double> values;
  final double? meanValue;
  final Color barColor;
  final Color meanLineColor;
  final Color textColor;

  _P2TBarChartPainter({
    required this.values,
    required this.meanValue,
    required this.barColor,
    required this.meanLineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double leftPad = 40;
    const double bottomPad = 20;
    const double topPad = 8;
    const double rightPad = 8;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final maxVal = values.reduce(math.max);
    final yMax = maxVal > 0 ? maxVal * 1.15 : 1.0;

    const barSpacing = 3.0;
    final totalSpacing = barSpacing * (values.length - 1);
    final barWidth = ((chartW - totalSpacing) / values.length).clamp(4.0, 28.0);

    final barPaint = Paint()..color = barColor.withValues(alpha: 0.7);

    for (int i = 0; i < values.length; i++) {
      final x = leftPad + i * (barWidth + barSpacing);
      final barH = (values[i] / yMax) * chartH;
      final rect = Rect.fromLTWH(x, topPad + chartH - barH, barWidth, barH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        barPaint,
      );
    }

    if (meanValue != null && meanValue! > 0) {
      final meanY = topPad + chartH - (meanValue! / yMax) * chartH;
      final dashPaint =
          Paint()
            ..color = meanLineColor
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      const dashLen = 4.0;
      const gapLen = 3.0;
      double x = leftPad;
      while (x < leftPad + chartW) {
        canvas.drawLine(
          Offset(x, meanY),
          Offset(math.min(x + dashLen, leftPad + chartW), meanY),
          dashPaint,
        );
        x += dashLen + gapLen;
      }
    }

    final labelStyle = TextStyle(
      fontSize: 8,
      color: textColor,
      fontWeight: FontWeight.w500,
    );

    final xTp = TextPainter(
      text: TextSpan(text: 'Breath Cycle', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    xTp.paint(
      canvas,
      Offset(leftPad + chartW / 2 - xTp.width / 2, size.height - 4),
    );

    final yTp = TextPainter(
      text: TextSpan(text: 'RSA (ms)', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(6, topPad + chartH / 2 + yTp.width / 2);
    canvas.rotate(-math.pi / 2);
    yTp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _P2TBarChartPainter old) =>
      old.values != values || old.meanValue != meanValue;
}

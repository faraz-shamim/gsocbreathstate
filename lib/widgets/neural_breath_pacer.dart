// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:math' as math;

import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NeuralBreathPacer extends StatelessWidget {
  final String phaseLabel;
  final double phaseProgress;
  final double cycleProgress;
  final int secondsRemaining;
  final double rateBpm;
  final double? resonanceFrequencyHz;
  final String? helperText;
  final bool compact;
  final bool showMetricChips;
  final bool showCoherenceOverlay;
  final double? coherenceScore;
  final bool hasHoldPhase;
  final bool hasEmptyHoldPhase;
  final double? inhaleFraction;
  final double? holdFraction;
  final double? exhaleFraction;
  final double? emptyHoldFraction;
  final double? height;
  final bool fillParent;
  final bool edgeToEdge;
  final bool showCenterCountdown;
  final bool showPhaseRail;

  const NeuralBreathPacer({
    super.key,
    required this.phaseLabel,
    required this.phaseProgress,
    required this.cycleProgress,
    required this.secondsRemaining,
    required this.rateBpm,
    this.resonanceFrequencyHz,
    this.helperText,
    this.compact = false,
    this.showMetricChips = true,
    this.showCoherenceOverlay = false,
    this.coherenceScore,
    this.hasHoldPhase = false,
    this.hasEmptyHoldPhase = false,
    this.inhaleFraction,
    this.holdFraction,
    this.exhaleFraction,
    this.emptyHoldFraction,
    this.height,
    this.fillParent = false,
    this.edgeToEdge = false,
    this.showCenterCountdown = true,
    this.showPhaseRail = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final visibleProgress =
        reduceMotion ? _phaseAnchor(phaseLabel) : phaseProgress;
    final visibleCycle =
        reduceMotion ? _cycleAnchor(phaseLabel) : cycleProgress;
    final defaultHeight = compact ? 188.0 : 292.0;
    final fg = AppTheme.foreground(isDark);
    final muted = AppTheme.muted(isDark);

    return Semantics(
      label:
          'Breathing guide. $phaseLabel. $secondsRemaining seconds remaining. ${rateBpm.toStringAsFixed(1)} breaths per minute.',
      child: Builder(
        builder: (context) {
          final visual = LayoutBuilder(
            builder: (context, constraints) {
              final visualHeight =
                  fillParent && constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : height ?? defaultHeight;
              return SizedBox(
                height: visualHeight,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NeuralWavePainter(
                          isDark: isDark,
                          phaseProgress: visibleProgress.clamp(0.0, 1.0),
                          cycleProgress: visibleCycle.clamp(0.0, 1.0),
                          phaseLabel: phaseLabel,
                          reduceMotion: reduceMotion,
                          showCoherenceOverlay: showCoherenceOverlay,
                          coherenceScore: coherenceScore,
                          hasHoldPhase: hasHoldPhase,
                          hasEmptyHoldPhase: hasEmptyHoldPhase,
                          inhaleFraction: inhaleFraction,
                          holdFraction: holdFraction,
                          exhaleFraction: exhaleFraction,
                          emptyHoldFraction: emptyHoldFraction,
                          edgeToEdge: edgeToEdge,
                        ),
                      ),
                    ),
                    if (showCenterCountdown)
                      Positioned(
                        top: compact ? 42 : 68,
                        child: Column(
                          children: [
                            Text(
                              secondsRemaining
                                  .clamp(0, 99)
                                  .toString()
                                  .padLeft(2, '0'),
                              style: AppTheme.monoNumeral(
                                color: fg,
                                fontSize: compact ? 34 : 48,
                                fontWeight: FontWeight.w800,
                              ).copyWith(height: 0.96),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phaseLabel,
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppTheme.clinicalTeal,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (showMetricChips)
                      Positioned(
                        left: edgeToEdge ? 8 : 0,
                        right: edgeToEdge ? 8 : 0,
                        bottom: compact ? 12 : 24,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 18,
                          ),
                          child: Row(
                            children: [
                              _DataChip(
                                label: '${rateBpm.toStringAsFixed(1)} BPM',
                                color: AppTheme.clinicalTeal,
                              ),
                              const Spacer(),
                              _DataChip(
                                label:
                                    resonanceFrequencyHz == null
                                        ? 'RF pending'
                                        : 'RF ${resonanceFrequencyHz!.toStringAsFixed(3)} Hz',
                                color: AppTheme.clinicalCyan,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );

          if (fillParent) return visual;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              visual,
              if (showPhaseRail) ...[
                const SizedBox(height: 12),
                _PhaseRail(
                  active: phaseLabel,
                  hasHoldPhase: hasHoldPhase,
                  hasEmptyHoldPhase: hasEmptyHoldPhase,
                ),
              ],
              if (helperText != null && helperText!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  helperText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  double _phaseAnchor(String label) {
    switch (label.toLowerCase()) {
      case 'inhale':
        return 0.55;
      case 'exhale':
        return 0.35;
      case 'hold':
      case 'hold empty':
        return 0.92;
      case 'prepare':
        return 0.12;
      default:
        return 0.0;
    }
  }

  double _cycleAnchor(String label) {
    final waveFractions = _normalizedWaveFractions(
      inhaleFraction: inhaleFraction,
      holdFraction: holdFraction,
      exhaleFraction: exhaleFraction,
      emptyHoldFraction: emptyHoldFraction,
    );

    switch (label.toLowerCase()) {
      case 'inhale':
        return waveFractions.inhale * 0.5;
      case 'hold':
        return waveFractions.inhale + waveFractions.hold * 0.5;
      case 'exhale':
        return waveFractions.inhale +
            waveFractions.hold +
            waveFractions.exhale * 0.5;
      case 'hold empty':
        return waveFractions.inhale +
            waveFractions.hold +
            waveFractions.exhale +
            waveFractions.emptyHold * 0.5;
      case 'prepare':
        return 0.96;
      default:
        return 0.0;
    }
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DataChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: AppTheme.monoNumeral(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PhaseRail extends StatelessWidget {
  final String active;
  final bool hasHoldPhase;
  final bool hasEmptyHoldPhase;

  const _PhaseRail({
    required this.active,
    required this.hasHoldPhase,
    required this.hasEmptyHoldPhase,
  });

  @override
  Widget build(BuildContext context) {
    final phases = [
      'Inhale',
      if (hasHoldPhase) 'Hold',
      'Exhale',
      if (hasEmptyHoldPhase) 'Hold Empty',
    ];
    return Row(
      children: [
        for (final phase in phases)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: phase == phases.last ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                decoration: BoxDecoration(
                  color:
                      active == phase
                          ? AppTheme.clinicalTeal
                          : AppTheme.clinicalTeal.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NeuralWavePainter extends CustomPainter {
  final bool isDark;
  final double phaseProgress;
  final double cycleProgress;
  final String phaseLabel;
  final bool reduceMotion;
  final bool showCoherenceOverlay;
  final double? coherenceScore;
  final bool hasHoldPhase;
  final bool hasEmptyHoldPhase;
  final double? inhaleFraction;
  final double? holdFraction;
  final double? exhaleFraction;
  final double? emptyHoldFraction;
  final bool edgeToEdge;

  _NeuralWavePainter({
    required this.isDark,
    required this.phaseProgress,
    required this.cycleProgress,
    required this.phaseLabel,
    required this.reduceMotion,
    required this.showCoherenceOverlay,
    required this.coherenceScore,
    required this.hasHoldPhase,
    required this.hasEmptyHoldPhase,
    required this.inhaleFraction,
    required this.holdFraction,
    required this.exhaleFraction,
    required this.emptyHoldFraction,
    required this.edgeToEdge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.15),
            radius: edgeToEdge ? 1.05 : 0.82,
            colors: [
              AppTheme.clinicalTeal.withValues(
                alpha:
                    edgeToEdge
                        ? (isDark ? 0.18 : 0.10)
                        : (isDark ? 0.13 : 0.08),
              ),
              Colors.transparent,
            ],
          ).createShader(rect);
    if (edgeToEdge) {
      canvas.drawRect(rect, bgPaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(26)),
        bgPaint,
      );
    }

    final gridPaint =
        Paint()
          ..color = AppTheme.gridline(isDark)
          ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(edgeToEdge ? 0 : 8, y),
        Offset(size.width - (edgeToEdge ? 0 : 8), y),
        gridPaint,
      );
    }

    final midY = size.height * (edgeToEdge ? 0.48 : 0.50);
    final amplitude = size.height * (edgeToEdge ? 0.26 : 0.18);
    final left = edgeToEdge ? -size.width * 0.18 : 18.0;
    final right = edgeToEdge ? size.width * 1.18 : size.width - 18.0;
    final width = right - left;
    final markerAnchor = edgeToEdge ? 0.50 : 0.58;

    double normalize(double value) {
      final wrapped = value % 1.0;
      return wrapped < 0 ? wrapped + 1.0 : wrapped;
    }

    double smoothStep(double x) => x * x * (3 - 2 * x);

    final waveFractions = _normalizedWaveFractions(
      inhaleFraction: inhaleFraction,
      holdFraction: holdFraction,
      exhaleFraction: exhaleFraction,
      emptyHoldFraction: emptyHoldFraction,
    );

    final hasExplicitFractions =
        inhaleFraction != null ||
        holdFraction != null ||
        exhaleFraction != null ||
        emptyHoldFraction != null;

    double waveValue(double t) {
      final p = normalize(t);
      if (!hasExplicitFractions && !hasHoldPhase && !hasEmptyHoldPhase) {
        return -math.cos(p * math.pi * 2);
      }

      var phaseStart = 0.0;
      if (waveFractions.inhale > 0) {
        final phaseEnd = phaseStart + waveFractions.inhale;
        if (p < phaseEnd) {
          return -1 + 2 * smoothStep((p - phaseStart) / waveFractions.inhale);
        }
        phaseStart = phaseEnd;
      }
      if (waveFractions.hold > 0) {
        final phaseEnd = phaseStart + waveFractions.hold;
        if (p < phaseEnd) return 1;
        phaseStart = phaseEnd;
      }
      if (waveFractions.exhale > 0) {
        final phaseEnd = phaseStart + waveFractions.exhale;
        if (p < phaseEnd) {
          return 1 - 2 * smoothStep((p - phaseStart) / waveFractions.exhale);
        }
      }
      return -1;
    }

    Offset markerPoint({double ampScale = 1}) {
      final x = edgeToEdge ? size.width * 0.50 : left + width * markerAnchor;
      final y = midY - waveValue(cycleProgress) * amplitude * ampScale;
      return Offset(x, y);
    }

    Path buildWave({double ampScale = 1, double phaseShift = 0}) {
      final path = Path();
      final segments = edgeToEdge ? 220 : 160;
      for (var i = 0; i <= segments; i++) {
        final xRatio = i / segments;
        final shifted = cycleProgress + (xRatio - markerAnchor) + phaseShift;
        final p = Offset(
          left + width * xRatio,
          midY - waveValue(shifted) * amplitude * ampScale,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      return path;
    }

    final trailPaint =
        Paint()
          ..color = AppTheme.clinicalTeal.withValues(
            alpha: isDark ? 0.18 : 0.13,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = edgeToEdge ? 13 : 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(buildWave(), trailPaint);

    final guidePaint =
        Paint()
          ..color = AppTheme.clinicalTeal.withValues(
            alpha: isDark ? 0.86 : 0.95,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = edgeToEdge ? 4.2 : 3.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(buildWave(), guidePaint);

    if (showCoherenceOverlay) {
      final coherence =
          coherenceScore == null
              ? 1.0
              : (coherenceScore!.clamp(0, 100).toDouble() / 100);
      final coherencePath = buildWave();
      if (coherence > 0.18) {
        canvas.drawPath(
          coherencePath,
          Paint()
            ..color = AppTheme.cardiacRose.withValues(
              alpha: (0.04 + coherence * 0.12).clamp(0.04, 0.16).toDouble(),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = edgeToEdge ? 13 : 8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      final cardiacPaint =
          Paint()
            ..color = AppTheme.cardiacRose.withValues(
              alpha: (0.30 + coherence * 0.46).clamp(0.30, 0.76).toDouble(),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = (edgeToEdge ? 2.4 : 2.0) + coherence * 1.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(coherencePath, cardiacPaint);
    }

    final marker = markerPoint();
    final markerWash =
        Paint()
          ..color = AppTheme.clinicalTeal.withValues(
            alpha: reduceMotion ? 0.12 : 0.20,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      marker,
      reduceMotion ? 12 : 18 + phaseProgress * 4,
      markerWash,
    );
    canvas.drawCircle(
      marker,
      7.5,
      Paint()..color = isDark ? AppTheme.graphite : AppTheme.pureWhite,
    );
    canvas.drawCircle(marker, 5.2, Paint()..color = AppTheme.clinicalTeal);
  }

  @override
  bool shouldRepaint(covariant _NeuralWavePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.phaseLabel != phaseLabel ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.showCoherenceOverlay != showCoherenceOverlay ||
        oldDelegate.coherenceScore != coherenceScore ||
        oldDelegate.hasHoldPhase != hasHoldPhase ||
        oldDelegate.hasEmptyHoldPhase != hasEmptyHoldPhase ||
        oldDelegate.inhaleFraction != inhaleFraction ||
        oldDelegate.holdFraction != holdFraction ||
        oldDelegate.exhaleFraction != exhaleFraction ||
        oldDelegate.emptyHoldFraction != emptyHoldFraction ||
        oldDelegate.edgeToEdge != edgeToEdge;
  }
}

class _BreathWaveFractions {
  final double inhale;
  final double hold;
  final double exhale;
  final double emptyHold;

  const _BreathWaveFractions({
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.emptyHold,
  });
}

_BreathWaveFractions _normalizedWaveFractions({
  double? inhaleFraction,
  double? holdFraction,
  double? exhaleFraction,
  double? emptyHoldFraction,
}) {
  final inhale = (inhaleFraction ?? 0.34).clamp(0.0, 1.0).toDouble();
  final hold = (holdFraction ?? 0.22).clamp(0.0, 1.0).toDouble();
  final exhale = (exhaleFraction ?? 0.36).clamp(0.0, 1.0).toDouble();
  final emptyHold = (emptyHoldFraction ?? 0.08).clamp(0.0, 1.0).toDouble();
  final total = inhale + hold + exhale + emptyHold;
  if (total <= 0) {
    return const _BreathWaveFractions(
      inhale: 0.34,
      hold: 0.22,
      exhale: 0.36,
      emptyHold: 0.08,
    );
  }

  return _BreathWaveFractions(
    inhale: inhale / total,
    hold: hold / total,
    exhale: exhale / total,
    emptyHold: emptyHold / total,
  );
}

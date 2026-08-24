// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:math' as math;

import 'package:breath_state/models/breathing_protocol.dart';
import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/breathing_sound_toggle.dart';
import 'package:breath_state/widgets/neural_breath_pacer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GuidedBreathing extends StatefulWidget {
  final String sessionTitle;
  final Duration inhaleDuration;
  final Duration holdDuration;
  final Duration exhaleDuration;
  final Duration emptyHoldDuration;
  final Duration? totalDuration;
  final double? resonanceFrequency;

  final bool showStopButton;

  const GuidedBreathing({
    super.key,
    this.sessionTitle = 'Breathing',
    required this.inhaleDuration,
    required this.holdDuration,
    required this.exhaleDuration,
    this.emptyHoldDuration = Duration.zero,
    this.totalDuration,
    this.resonanceFrequency,
    this.showStopButton = true,
  });

  @override
  State<GuidedBreathing> createState() => _GuidedBreathingState();
}

class _GuidedBreathingState extends State<GuidedBreathing>
    with TickerProviderStateMixin {
  static const Duration _introDuration = Duration(seconds: 5);

  late final AnimationController _introController;
  late final AnimationController _phaseController;
  late final BreathingSoundProvider _soundProvider;
  late final BreathingProtocol _protocol;

  BreathingPhase _phase = BreathingPhase.inhale;
  Timer? _totalSessionTimer;
  int _totalSecondsElapsed = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _soundProvider = context.read<BreathingSoundProvider>();
    unawaited(_soundProvider.beginSession());
    _protocol = BreathingProtocol(
      inhaleDuration: widget.inhaleDuration,
      holdDuration: widget.holdDuration,
      exhaleDuration: widget.exhaleDuration,
      emptyHoldDuration: widget.emptyHoldDuration,
    );
    _phase = _protocol.firstPhase;

    _introController = AnimationController(
      vsync: this,
      duration: _introDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _started = true;
        _startPhase(_protocol.firstPhase);
        _startTotalSessionTimer();
      }
    });

    _phaseController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _startPhase(_protocol.nextPhase(_phase));
        }
      });

    _introController.forward();
  }

  void _startTotalSessionTimer() {
    if (widget.totalDuration == null) return;

    _totalSessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _totalSecondsElapsed++;
      });

      if (_totalSecondsElapsed >= widget.totalDuration!.inSeconds) {
        timer.cancel();
        _endSessionComplete();
      }
    });
  }

  void _endSessionComplete() {
    if (!mounted) return;
    _phaseController.stop();
    Navigator.of(context).pop();
  }

  void _startPhase(BreathingPhase phase) {
    final duration = _protocol.durationFor(phase);
    setState(() => _phase = phase);
    switch (phase) {
      case BreathingPhase.inhale:
        unawaited(
          _soundProvider.cue(BreathingCue.inhale, sustainFor: duration),
        );
      case BreathingPhase.hold:
        unawaited(
          _soundProvider.repeatCueForHold(
            BreathingCue.inhale,
            duration: duration,
          ),
        );
      case BreathingPhase.exhale:
        unawaited(
          _soundProvider.cue(BreathingCue.exhale, sustainFor: duration),
        );
      case BreathingPhase.emptyHold:
        unawaited(
          _soundProvider.repeatCueForHold(
            BreathingCue.exhale,
            duration: duration,
          ),
        );
    }
    _phaseController
      ..duration = duration
      ..forward(from: 0);
  }

  Duration get _cycleDuration => _protocol.cycleDuration;

  String get _phaseLabel {
    if (!_started) return 'Prepare';
    return _phase.label;
  }

  double get _phaseStartFraction => _protocol.startFractionFor(_phase);

  double get _cycleProgress {
    if (!_started) return 0.96;
    final cycleMs = _cycleDuration.inMilliseconds;
    if (cycleMs <= 0) return 0;
    final phaseMs = _protocol.durationFor(_phase).inMilliseconds;
    return (_phaseStartFraction + (_phaseController.value * phaseMs / cycleMs))
        .clamp(0.0, 1.0);
  }

  int get _secondsRemaining {
    if (!_started) {
      final ms =
          _introDuration.inMilliseconds *
          (1 - _introController.value.clamp(0.0, 1.0));
      return (ms / 1000).ceil().clamp(0, 99);
    }
    final ms =
        _protocol.durationFor(_phase).inMilliseconds *
        (1 - _phaseController.value.clamp(0.0, 1.0));
    return (ms / 1000).ceil().clamp(0, 99);
  }

  double get _rateBpm {
    final cycleMs = _cycleDuration.inMilliseconds;
    if (cycleMs <= 0) return 6.0;
    return 60000 / cycleMs;
  }

  double? get _resonanceFrequencyHz {
    final rate = widget.resonanceFrequency;
    if (rate == null || rate <= 0) return null;
    return rate / 60.0;
  }

  double get _sessionProgress {
    if (!_started) return _introController.value.clamp(0.0, 1.0);
    if (widget.totalDuration == null || widget.totalDuration!.inSeconds <= 0) {
      return _phaseController.value.clamp(0.0, 1.0);
    }
    return (_totalSecondsElapsed / widget.totalDuration!.inSeconds).clamp(
      0.0,
      1.0,
    );
  }

  Color get _phaseColor {
    switch (_phaseLabel) {
      case 'Inhale':
        return AppTheme.clinicalTeal;
      case 'Hold':
      case 'Hold Empty':
        return AppTheme.clinicalCyan;
      case 'Exhale':
        return AppTheme.cardiacRose;
      case 'Prepare':
      default:
        return AppTheme.muted(Theme.of(context).brightness == Brightness.dark);
    }
  }

  String _formatTimer() {
    if (widget.totalDuration == null) return '';
    final remaining = widget.totalDuration!.inSeconds - _totalSecondsElapsed;
    final clampedRemaining = remaining < 0 ? 0 : remaining;
    final m = (clampedRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (clampedRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    unawaited(_soundProvider.endSession());
    _introController.dispose();
    _phaseController.dispose();
    _totalSessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalTimer = _formatTimer();
    final isRfBreathing =
        widget.resonanceFrequency != null && widget.resonanceFrequency! > 0;
    final rateBpm = widget.resonanceFrequency ?? _rateBpm;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_introController, _phaseController]),
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  children: [
                    _BreathSessionHeader(
                      title: widget.sessionTitle,
                      rateLabel:
                          isRfBreathing
                              ? '${rateBpm.toStringAsFixed(1)} BPM'
                              : null,
                      rfLabel:
                          _resonanceFrequencyHz == null
                              ? null
                              : '${_resonanceFrequencyHz!.toStringAsFixed(3)} Hz',
                    ),
                    const SizedBox(height: 14),
                    _PhasePrompt(
                      phaseLabel: _phaseLabel,
                      secondsRemaining: _secondsRemaining,
                      color: _phaseColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: NeuralBreathPacer(
                        phaseLabel: _phaseLabel,
                        phaseProgress:
                            _started
                                ? _phaseController.value
                                : _introController.value,
                        cycleProgress: _cycleProgress,
                        secondsRemaining: _secondsRemaining,
                        rateBpm: rateBpm,
                        resonanceFrequencyHz: _resonanceFrequencyHz,
                        showMetricChips: isRfBreathing,
                        showCoherenceOverlay: isRfBreathing,
                        coherenceScore: isRfBreathing ? 100 : null,
                        hasHoldPhase: widget.holdDuration > Duration.zero,
                        hasEmptyHoldPhase:
                            widget.emptyHoldDuration > Duration.zero,
                        inhaleFraction: _protocol.fractionFor(
                          BreathingPhase.inhale,
                        ),
                        holdFraction: _protocol.fractionFor(
                          BreathingPhase.hold,
                        ),
                        exhaleFraction: _protocol.fractionFor(
                          BreathingPhase.exhale,
                        ),
                        emptyHoldFraction: _protocol.fractionFor(
                          BreathingPhase.emptyHold,
                        ),
                        showCenterCountdown: false,
                        showPhaseRail: false,
                        fillParent: true,
                        edgeToEdge: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SessionArcTimer(
                      phaseLabel: _phaseLabel,
                      sessionLabel:
                          totalTimer.isEmpty
                              ? '${_secondsRemaining}s'
                              : totalTimer,
                      progress: _sessionProgress,
                      phaseProgress:
                          _started
                              ? _phaseController.value
                              : _introController.value,
                      color: _phaseColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    if (widget.showStopButton)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('End session'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                            side: BorderSide(
                              color: AppTheme.signalBad.withValues(
                                alpha: isDark ? 0.36 : 0.30,
                              ),
                            ),
                            foregroundColor: AppTheme.signalBad,
                            backgroundColor: AppTheme.signalBad.withValues(
                              alpha: isDark ? 0.08 : 0.04,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BreathSessionHeader extends StatelessWidget {
  final String title;
  final String? rateLabel;
  final String? rfLabel;

  const _BreathSessionHeader({
    required this.title,
    required this.rateLabel,
    required this.rfLabel,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      if (rateLabel != null)
        _HeaderChip(label: rateLabel!, color: AppTheme.clinicalTeal),
      if (rfLabel != null)
        _HeaderChip(label: rfLabel!, color: AppTheme.cardiacRose),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 12),
            const BreathingSoundToggle(compact: true),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: AppTheme.monoNumeral(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PhasePrompt extends StatelessWidget {
  final String phaseLabel;
  final int secondsRemaining;
  final Color color;
  final bool isDark;

  const _PhasePrompt({
    required this.phaseLabel,
    required this.secondsRemaining,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foreground(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phaseLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 44,
            letterSpacing: 0,
            height: 0.92,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${secondsRemaining.clamp(0, 99)}s',
          style: AppTheme.monoNumeral(
            color: fg,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ).copyWith(height: 1),
        ),
      ],
    );
  }
}

class _SessionArcTimer extends StatelessWidget {
  final String phaseLabel;
  final String sessionLabel;
  final double progress;
  final double phaseProgress;
  final Color color;
  final bool isDark;

  const _SessionArcTimer({
    required this.phaseLabel,
    required this.sessionLabel,
    required this.progress,
    required this.phaseProgress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcTimerPainter(
                progress: progress,
                phaseProgress: phaseProgress,
                color: color,
                isDark: isDark,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sessionLabel,
                    style: AppTheme.monoNumeral(
                      color: AppTheme.foreground(isDark),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ).copyWith(height: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phaseLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcTimerPainter extends CustomPainter {
  final double progress;
  final double phaseProgress;
  final Color color;
  final bool isDark;

  _ArcTimerPainter({
    required this.progress,
    required this.phaseProgress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.90);
    final radius = math.min(size.width * 0.54, size.height * 1.05);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 1.12;
    const sweep = math.pi * 0.76;

    final trackPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = AppTheme.hairline(isDark).withValues(alpha: 0.78);
    canvas.drawArc(rect, start, sweep, false, trackPaint);

    final sessionPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: isDark ? 0.82 : 0.90);
    canvas.drawArc(
      rect,
      start,
      sweep * progress.clamp(0.0, 1.0),
      false,
      sessionPaint,
    );

    final markerAngle = start + sweep * phaseProgress.clamp(0.0, 1.0);
    final marker = Offset(
      center.dx + math.cos(markerAngle) * radius,
      center.dy + math.sin(markerAngle) * radius,
    );
    canvas.drawCircle(
      marker,
      10,
      Paint()..color = isDark ? AppTheme.graphite : AppTheme.pureWhite,
    );
    canvas.drawCircle(marker, 6.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ArcTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

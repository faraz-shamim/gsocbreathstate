                                                                  
library;

import 'dart:async';

import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/services/biofeedback/adaptive_breathing_controller.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/neural_breath_pacer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdaptiveBreathingBubble extends StatefulWidget {
  final Stream<AdaptiveBreathingState> stateStream;
  final Stream<double>? coherenceStream;

                                                               
  final int initialInhaleMs;
  final int initialExhaleMs;

  const AdaptiveBreathingBubble({
    super.key,
    required this.stateStream,
    this.coherenceStream,
    this.initialInhaleMs = 5000,
    this.initialExhaleMs = 5000,
  });

  @override
  State<AdaptiveBreathingBubble> createState() =>
      _AdaptiveBreathingBubbleState();
}

enum _AdaptivePhase { inhale, exhale }

class _AdaptiveBreathingBubbleState extends State<AdaptiveBreathingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phaseController;
  StreamSubscription<AdaptiveBreathingState>? _stateSub;
  StreamSubscription<double>? _coherenceSub;

  _AdaptivePhase _phase = _AdaptivePhase.inhale;
  int _inhaleMs = 5000;
  int _exhaleMs = 5000;
  double _currentRateBpm = 6.0;
  String _adjustReason = 'Initial rate';
  double _coherence = 0;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<BreathingSoundProvider>().prepareForSession());
    _inhaleMs = widget.initialInhaleMs;
    _exhaleMs = widget.initialExhaleMs;
    _currentRateBpm = 60000.0 / (_inhaleMs + _exhaleMs);

    _phaseController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _startPhase(_nextPhase(_phase));
        }
      });
    _stateSub = widget.stateStream.listen(_onStateUpdate);
    _listenToCoherence();
    _startPhase(_AdaptivePhase.inhale);
  }

  void _onStateUpdate(AdaptiveBreathingState state) {
    if (!mounted) return;
    setState(() {
      _inhaleMs = state.inhaleMs;
      _exhaleMs = state.exhaleMs;
      _currentRateBpm = state.currentRateBpm;
      _adjustReason = state.adjustmentReason;
      if (widget.coherenceStream == null) {
        _coherence = state.coherence;
      }
    });
  }

  void _listenToCoherence() {
    _coherenceSub?.cancel();
    final stream = widget.coherenceStream;
    if (stream == null) return;
    _coherenceSub = stream.listen((score) {
      if (!mounted) return;
      setState(() {
        _coherence = score.clamp(0, 100).toDouble();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AdaptiveBreathingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coherenceStream != widget.coherenceStream) {
      _listenToCoherence();
    }
    if (oldWidget.stateStream != widget.stateStream) {
      _stateSub?.cancel();
      _stateSub = widget.stateStream.listen(_onStateUpdate);
    }
  }

  void _startPhase(_AdaptivePhase phase) {
    final duration = _durationFor(phase);
    setState(() => _phase = phase);
    final cue =
        phase == _AdaptivePhase.inhale
            ? BreathingCue.inhale
            : BreathingCue.exhale;
    unawaited(
      context.read<BreathingSoundProvider>().cue(cue, sustainFor: duration),
    );
    _phaseController
      ..duration = duration
      ..forward(from: 0);
  }

  _AdaptivePhase _nextPhase(_AdaptivePhase phase) {
    switch (phase) {
      case _AdaptivePhase.inhale:
        return _AdaptivePhase.exhale;
      case _AdaptivePhase.exhale:
        return _AdaptivePhase.inhale;
    }
  }

  Duration _durationFor(_AdaptivePhase phase) {
    switch (phase) {
      case _AdaptivePhase.inhale:
        return Duration(milliseconds: _inhaleMs);
      case _AdaptivePhase.exhale:
        return Duration(milliseconds: _exhaleMs);
    }
  }

  Duration get _cycleDuration => Duration(milliseconds: _inhaleMs + _exhaleMs);

  String get _phaseLabel {
    switch (_phase) {
      case _AdaptivePhase.inhale:
        return 'Inhale';
      case _AdaptivePhase.exhale:
        return 'Exhale';
    }
  }

  double get _cycleProgress {
    final cycleMs = _cycleDuration.inMilliseconds;
    if (cycleMs <= 0) return 0;
    final start = switch (_phase) {
      _AdaptivePhase.inhale => 0.0,
      _AdaptivePhase.exhale => _inhaleMs / cycleMs,
    };
    final phaseMs = _durationFor(_phase).inMilliseconds;
    return (start + _phaseController.value * phaseMs / cycleMs).clamp(0.0, 1.0);
  }

  int get _secondsRemaining {
    final ms =
        _durationFor(_phase).inMilliseconds *
        (1 - _phaseController.value.clamp(0.0, 1.0));
    return (ms / 1000).ceil().clamp(0, 99);
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _stateSub?.cancel();
    _coherenceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseController,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuralBreathPacer(
              phaseLabel: _phaseLabel,
              phaseProgress: _phaseController.value,
              cycleProgress: _cycleProgress,
              secondsRemaining: _secondsRemaining,
              rateBpm: _currentRateBpm,
              compact: true,
              showMetricChips: false,
              showCoherenceOverlay: true,
              coherenceScore: _coherence,
              hasHoldPhase: false,
              helperText: _adjustReason,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InlineSignal(
                  label: 'Coherence',
                  value: _coherence <= 0 ? '--' : _coherence.round().toString(),
                  color:
                      _coherence >= 70
                          ? AppTheme.signalGood
                          : _coherence >= 40
                          ? AppTheme.signalWarn
                          : AppTheme.signalBad,
                ),
                const SizedBox(width: 10),
                _InlineSignal(
                  label: 'Adaptive rate',
                  value: '${_currentRateBpm.toStringAsFixed(1)} BPM',
                  color: AppTheme.clinicalTeal,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InlineSignal extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InlineSignal({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.monoNumeral(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted(isDark)),
          ),
        ],
      ),
    );
  }
}

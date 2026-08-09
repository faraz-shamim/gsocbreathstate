import 'package:breath_state/models/breathing_protocol.dart';
import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({super.key});

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen> {
  int _equalBreathingSeconds = 4;
  _CustomProtocolSettings _customSettings = const _CustomProtocolSettings(
    inputMode: _CustomProtocolInputMode.seconds,
    phaseValues: _ProtocolPhaseValues(
      inhale: 4,
      hold: 0,
      exhale: 6,
      emptyHold: 0,
    ),
    cycleSeconds: 10,
    sessionMinutes: 5,
  );

  void _startSession(
    BuildContext context,
    int index,
    _BreathingOption option,
    int durationMinutes, {
    int? equalPhaseSeconds,
  }) {
    if (index == 0) {
      final patient = context.read<PatientProvider>().activePatient;
      final freq =
          patient?.resonanceFrequency ?? ResonanceFrequency.userResonanceFreq;
      final appMode = context.read<AppModeProvider>().mode;

      if (freq == 0) {
        if (appMode == AppMode.patientWithoutPolar) {
          _showManualRateSetupDialog(context, durationMinutes);
        } else {
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    "Resonance Frequency Needed",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  content: Text(
                    "You need to measure your resonance frequency first before starting guided breathing.",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final measureIndex = context
                            .read<AppModeProvider>()
                            .indexForDestination('Record', fallback: 0);
                        context.read<NavBarProvider>().changeIndex(
                          measureIndex,
                        );
                      },
                      child: const Text(
                        "Go to Measure",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
          );
        }
      } else {
        _startSessionWithRate(context, freq, durationMinutes);
      }
    } else {
      final inhaleSeconds =
          index == 2
              ? equalPhaseSeconds ?? _equalBreathingSeconds
              : option.inhale;
      final exhaleSeconds =
          index == 2
              ? equalPhaseSeconds ?? _equalBreathingSeconds
              : option.exhale;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GuidedBreathing(
                sessionTitle: option.title,
                inhaleDuration: Duration(seconds: inhaleSeconds),
                holdDuration: Duration(seconds: option.hold),
                exhaleDuration: Duration(seconds: exhaleSeconds),
                emptyHoldDuration: Duration(seconds: option.emptyHold),
                totalDuration: Duration(minutes: durationMinutes),
              ),
        ),
      );
    }
  }

  void _startSessionWithRate(
    BuildContext context,
    double rate,
    int durationMinutes,
  ) {
    final cycleDurationMs = (60000 / rate).round();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GuidedBreathing(
              sessionTitle: 'Resonance Breathing',
              inhaleDuration: Duration(milliseconds: cycleDurationMs ~/ 2),
              holdDuration: const Duration(milliseconds: 0),
              exhaleDuration: Duration(milliseconds: cycleDurationMs ~/ 2),
              emptyHoldDuration: Duration.zero,
              totalDuration: Duration(minutes: durationMinutes),
              resonanceFrequency: rate,
            ),
      ),
    );
  }

  Future<void> _saveManualRate(double rate) async {
    final patientProvider = context.read<PatientProvider>();
    final activePatient = patientProvider.activePatient;
    if (activePatient != null) {
      await patientProvider.updateResonanceFrequency(activePatient.id, rate);
    }
    ResonanceFrequency.userResonanceFreq = rate;
  }

  void _showManualRateSetupDialog(BuildContext context, int durationMinutes) {
    double tempRate = 6.0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cycleSecs = 60 / tempRate;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Set Resonance Frequency"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Select your target breathing rate in breaths per minute (BPM).",
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${tempRate.toStringAsFixed(1)} BPM",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emerald,
                    ),
                  ),
                  Text(
                    "Cycle: ${cycleSecs.toStringAsFixed(1)}s (${(cycleSecs / 2).toStringAsFixed(1)}s inhale / ${(cycleSecs / 2).toStringAsFixed(1)}s exhale)",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: tempRate,
                    min: 4.0,
                    max: 9.0,
                    divisions: 50,
                    activeColor: AppTheme.emerald,
                    inactiveColor: AppTheme.emerald.withValues(alpha: 0.2),
                    onChanged: (val) {
                      setModalState(() {
                        tempRate = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveManualRate(tempRate);
                    if (context.mounted) {
                      _startSessionWithRate(context, tempRate, durationMinutes);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: AppTheme.obsidian,
                  ),
                  child: const Text("Save & Start"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomProtocolBuilder(BuildContext context) async {
    final initial = _customSettings;
    var inputMode = initial.inputMode;
    var sessionMinutes = initial.sessionMinutes;
    final secondsControllers = _phaseControllers(
      inputMode == _CustomProtocolInputMode.seconds
          ? initial.phaseValues
          : initial.protocolPhaseSeconds,
    );
    final ratioControllers = _phaseControllers(
      inputMode == _CustomProtocolInputMode.ratio
          ? initial.phaseValues
          : initial.protocolPhaseSeconds,
    );
    final cycleController = TextEditingController(
      text: _formatProtocolValue(initial.cycleSeconds),
    );

    _ProtocolPhaseValues? readValues(
      Map<BreathingPhase, TextEditingController> controllers,
    ) {
      final values = [
        for (final phase in BreathingPhase.values)
          double.tryParse(controllers[phase]!.text.trim()),
      ];
      if (values.any((value) => value == null)) return null;
      return _ProtocolPhaseValues(
        inhale: values[0]!,
        hold: values[1]!,
        exhale: values[2]!,
        emptyHold: values[3]!,
      );
    }

    String? validationMessage() {
      final controllers =
          inputMode == _CustomProtocolInputMode.seconds
              ? secondsControllers
              : ratioControllers;
      final values = readValues(controllers);
      if (values == null) return 'Enter a number for every phase.';
      if (values.values.any((value) => value < 0)) {
        return 'Phase values cannot be negative.';
      }
      if (values.inhale <= 0 || values.exhale <= 0) {
        return 'Inhale and exhale must both be greater than zero.';
      }
      final maximum =
          inputMode == _CustomProtocolInputMode.seconds ? 60.0 : 20.0;
      if (values.values.any((value) => value > maximum)) {
        return inputMode == _CustomProtocolInputMode.seconds
            ? 'Each phase must be 60 seconds or less.'
            : 'Each ratio value must be 20 or less.';
      }
      if (inputMode == _CustomProtocolInputMode.ratio) {
        final cycleSeconds = double.tryParse(cycleController.text.trim());
        if (cycleSeconds == null || cycleSeconds < 2 || cycleSeconds > 120) {
          return 'Cycle duration must be between 2 and 120 seconds.';
        }
      }
      return null;
    }

    _CustomProtocolSettings? settingsFromInput() {
      if (validationMessage() != null) return null;
      final controllers =
          inputMode == _CustomProtocolInputMode.seconds
              ? secondsControllers
              : ratioControllers;
      return _CustomProtocolSettings(
        inputMode: inputMode,
        phaseValues: readValues(controllers)!,
        cycleSeconds:
            inputMode == _CustomProtocolInputMode.ratio
                ? double.tryParse(cycleController.text.trim()) ??
                    initial.cycleSeconds
                : readValues(controllers)!.total,
        sessionMinutes: sessionMinutes,
      );
    }

    final result = await showModalBottomSheet<_CustomProtocolSettings>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void adjustValue(
              TextEditingController controller,
              double delta,
              double maximum,
            ) {
              final current = double.tryParse(controller.text.trim()) ?? 0;
              final adjusted = (current + delta).clamp(0.0, maximum);
              controller
                ..text = _formatProtocolValue(adjusted)
                ..selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
              setModalState(() {});
            }

            final activeControllers =
                inputMode == _CustomProtocolInputMode.seconds
                    ? secondsControllers
                    : ratioControllers;
            final settings = settingsFromInput();
            final protocol = settings?.protocol;
            final error = validationMessage();
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.94,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Custom Protocol',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_CustomProtocolInputMode>(
                        segments: const [
                          ButtonSegment(
                            value: _CustomProtocolInputMode.seconds,
                            icon: Icon(Icons.timer_outlined),
                            label: Text('Seconds'),
                          ),
                          ButtonSegment(
                            value: _CustomProtocolInputMode.ratio,
                            icon: Icon(Icons.data_array_rounded),
                            label: Text('Ratio'),
                          ),
                        ],
                        selected: {inputMode},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setModalState(() => inputMode = selection.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      if (inputMode == _CustomProtocolInputMode.seconds)
                        for (final phase in BreathingPhase.values) ...[
                          _ProtocolPhaseField(
                            phase: phase,
                            controller: activeControllers[phase]!,
                            suffix: 'sec',
                            onChanged: () => setModalState(() {}),
                            onDecrease:
                                () => adjustValue(
                                  activeControllers[phase]!,
                                  -0.5,
                                  60,
                                ),
                            onIncrease:
                                () => adjustValue(
                                  activeControllers[phase]!,
                                  0.5,
                                  60,
                                ),
                          ),
                          if (phase != BreathingPhase.emptyHold)
                            const SizedBox(height: 10),
                        ]
                      else ...[
                        _ProtocolRatioPairField(
                          label: 'Inhale : Exhale',
                          leftController:
                              activeControllers[BreathingPhase.inhale]!,
                          rightController:
                              activeControllers[BreathingPhase.exhale]!,
                          leftKey: const ValueKey('custom-inhale-input'),
                          rightKey: const ValueKey('custom-exhale-input'),
                          onChanged: () => setModalState(() {}),
                        ),
                        const SizedBox(height: 14),
                        _ProtocolRatioPairField(
                          label:
                              'Post-inspiratory pause : '
                              'Post-expiratory pause',
                          leftController:
                              activeControllers[BreathingPhase.hold]!,
                          rightController:
                              activeControllers[BreathingPhase.emptyHold]!,
                          leftKey: const ValueKey('custom-hold-input'),
                          rightKey: const ValueKey('custom-emptyHold-input'),
                          onChanged: () => setModalState(() {}),
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 14),
                        _ProtocolNumberField(
                          label: 'Cycle duration',
                          controller: cycleController,
                          suffix: 'sec',
                          onChanged: () => setModalState(() {}),
                          onDecrease:
                              () => adjustValue(cycleController, -0.5, 120),
                          onIncrease:
                              () => adjustValue(cycleController, 0.5, 120),
                        ),
                      ],
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child:
                            protocol == null
                                ? Text(
                                  error ?? '',
                                  key: ValueKey(error),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.signalBad,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : _ProtocolSummary(
                                  key: ValueKey(
                                    '${protocol.cycleDuration.inMicroseconds}',
                                  ),
                                  protocol: protocol,
                                ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Session duration',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '$sessionMinutes min',
                            style: AppTheme.monoNumeral(
                              color: AppTheme.emerald,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: sessionMinutes.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        label: '$sessionMinutes min',
                        onChanged:
                            (value) => setModalState(
                              () => sessionMinutes = value.round(),
                            ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        key: const ValueKey('custom-protocol-start'),
                        onPressed:
                            settings == null
                                ? null
                                : () => Navigator.pop(sheetContext, settings),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start custom session'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppTheme.emerald,
                          foregroundColor: AppTheme.obsidian,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in [
      ...secondsControllers.values,
      ...ratioControllers.values,
      cycleController,
    ]) {
      controller.dispose();
    }
    if (result == null || !mounted) return;

    setState(() => _customSettings = result);
    final protocol = result.protocol;
    Navigator.push(
      this.context,
      MaterialPageRoute(
        builder:
            (context) => GuidedBreathing(
              sessionTitle: 'Custom Protocol',
              inhaleDuration: protocol.inhaleDuration,
              holdDuration: protocol.holdDuration,
              exhaleDuration: protocol.exhaleDuration,
              emptyHoldDuration: protocol.emptyHoldDuration,
              totalDuration: Duration(minutes: result.sessionMinutes),
            ),
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context,
    int index,
    _BreathingOption option,
  ) {
    final screenContext = context;
    int selectedVal = 5;
    int equalPhaseSeconds = _equalBreathingSeconds;
    final scrollController = FixedExtentScrollController(initialItem: 4);

    final patient = context.read<PatientProvider>().activePatient;
    double currentRate =
        patient?.resonanceFrequency ?? ResonanceFrequency.userResonanceFreq;
    if (currentRate == 0) currentRate = 6.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetMaxHeight = MediaQuery.sizeOf(ctx).height * 0.88;
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(maxHeight: sheetMaxHeight),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Session Duration",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Scroll to select duration",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 48,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 60,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withValues(
                                  alpha: isDark ? 0.14 : 0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppTheme.emerald.withValues(
                                    alpha: isDark ? 0.2 : 0.18,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 180,
                                  child: ListWheelScrollView.useDelegate(
                                    controller: scrollController,
                                    itemExtent: 48,
                                    perspective: 0.003,
                                    diameterRatio: 1.4,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (i) {
                                      setModalState(() => selectedVal = i + 1);
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          childCount: 60,
                                          builder: (context, i) {
                                            final val = i + 1;
                                            final isSelected =
                                                val == selectedVal;
                                            return Center(
                                              child: AnimatedDefaultTextStyle(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                style: TextStyle(
                                                  fontSize:
                                                      isSelected ? 28 : 20,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                  color:
                                                      isSelected
                                                          ? (isDark
                                                              ? Colors.white
                                                              : Colors.black)
                                                          : (isDark
                                                              ? Colors.white38
                                                              : Colors.black26),
                                                ),
                                                child: Text('$val'),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "min",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (index == 2) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          "Breath Length",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Use the same duration for inhale and exhale",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(
                              value: 4,
                              label: Text('4 seconds'),
                            ),
                            ButtonSegment<int>(
                              value: 5,
                              label: Text('5 seconds'),
                            ),
                          ],
                          selected: <int>{equalPhaseSeconds},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setModalState(
                              () => equalPhaseSeconds = selection.first,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (index == 0) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          "Resonance Frequency Rate",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${currentRate.toStringAsFixed(1)} BPM",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emerald,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Cycle: ${(60 / currentRate).toStringAsFixed(1)}s (${(30 / currentRate).toStringAsFixed(1)}s inhale / ${(30 / currentRate).toStringAsFixed(1)}s exhale)",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: currentRate,
                          min: 4.0,
                          max: 9.0,
                          divisions: 50,
                          activeColor: AppTheme.emerald,
                          inactiveColor: AppTheme.emerald.withValues(
                            alpha: 0.2,
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              currentRate = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (index == 0) {
                              await _saveManualRate(currentRate);
                            }
                            if (index == 2 && mounted) {
                              setState(
                                () =>
                                    _equalBreathingSeconds = equalPhaseSeconds,
                              );
                            }
                            if (screenContext.mounted) {
                              _startSession(
                                screenContext,
                                index,
                                option,
                                selectedVal,
                                equalPhaseSeconds: equalPhaseSeconds,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                          ),
                          child: const Text("Start"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_BreathingOption> breathingOptions = [
      _BreathingOption(
        title: "Resonance Breathing",
        description: "Your personalized breathing rate",
        color: AppTheme.dustyRose,
        icon: Icons.favorite_rounded,
        inhale: 0,
        hold: 0,
        exhale: 0,
      ),
      _BreathingOption(
        title: "Box Breathing",
        description: "Inhale, hold, exhale, hold",
        color: AppTheme.emerald,
        icon: Icons.crop_square_rounded,
        inhale: 4,
        hold: 4,
        exhale: 4,
        emptyHold: 4,
      ),
      _BreathingOption(
        title: "Equal Breathing",
        description: "Balanced ${_equalBreathingSeconds}s inhale and exhale",
        color: AppTheme.softSage,
        icon: Icons.balance_rounded,
        inhale: _equalBreathingSeconds,
        hold: 0,
        exhale: _equalBreathingSeconds,
        emptyHold: 0,
      ),
      _BreathingOption(
        title: "4-7-8 Breathing",
        description: "Relaxation and calmness",
        color: const Color(0xFF818CF8),
        icon: Icons.nightlight_round,
        inhale: 4,
        hold: 7,
        exhale: 8,
        emptyHold: 0,
      ),
      _BreathingOption(
        title: "Custom Protocol",
        description: "Independent phase timing or ratios",
        color: AppTheme.clinicalCyan,
        icon: Icons.tune_rounded,
        inhale: 4,
        hold: 0,
        exhale: 6,
        emptyHold: 0,
        isCustom: true,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);
    final gridCols = Responsive.gridColumns(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 24.0, hPad, 16.0),
                sliver: SliverToBoxAdapter(
                  child: ContentContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Guided Sessions",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                sliver: SliverToBoxAdapter(
                  child: ContentContainer(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio:
                            Responsive.isMobile(context) ? 0.68 : 0.78,
                      ),
                      itemCount: breathingOptions.length,
                      itemBuilder: (context, index) {
                        final option = breathingOptions[index];
                        return _BreathingCard(
                          option: option,
                          index: index,
                          onStart:
                              option.isCustom
                                  ? (_) => _showCustomProtocolBuilder(context)
                                  : (duration) => _startSession(
                                    context,
                                    index,
                                    option,
                                    duration,
                                  ),
                          onSettingsTap:
                              option.isCustom
                                  ? () => _showCustomProtocolBuilder(context)
                                  : () => _showDurationPicker(
                                    context,
                                    index,
                                    option,
                                  ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: Responsive.bottomListPadding(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingOption {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int inhale;
  final int hold;
  final int exhale;
  final int emptyHold;
  final bool isCustom;

  _BreathingOption({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.inhale,
    required this.hold,
    required this.exhale,
    this.emptyHold = 0,
    this.isCustom = false,
  });
}

class _BreathingCard extends StatelessWidget {
  final _BreathingOption option;
  final int index;
  final Function(int) onStart;
  final VoidCallback onSettingsTap;

  const _BreathingCard({
    required this.option,
    required this.index,
    required this.onStart,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgOpacity = isDark ? 0.18 : 0.06;
    final iconBgOpacity = isDark ? 0.28 : 0.12;
    final shadowOpacity = isDark ? 0.28 : 0.10;

    return ScaleOnPress(
      onTap: () => onStart(5),
      scaleFactor: 0.985,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        borderRadius: 8,
        color: option.color.withValues(alpha: cardBgOpacity),
        hasBorder: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: iconBgOpacity),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: option.color.withValues(alpha: shadowOpacity),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                option.icon,
                size: 28,
                color: isDark ? Colors.white : option.color,
              ),
            ),
            const Spacer(flex: 2),
            Text(
              option.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF334155),
                height: 1.3,
              ),
            ),
            const Spacer(flex: 1),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: option.color.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "5 mins",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: option.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Session settings',
                  icon: Icon(
                    Icons.settings_rounded,
                    size: 20,
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.62)
                            : const Color(0xFF475569),
                  ),
                  onPressed: onSettingsTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _CustomProtocolInputMode { seconds, ratio }

class _ProtocolPhaseValues {
  final double inhale;
  final double hold;
  final double exhale;
  final double emptyHold;

  const _ProtocolPhaseValues({
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.emptyHold,
  });

  List<double> get values => [inhale, hold, exhale, emptyHold];

  double get total => values.fold<double>(0, (sum, value) => sum + value);

  double valueFor(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return inhale;
      case BreathingPhase.hold:
        return hold;
      case BreathingPhase.exhale:
        return exhale;
      case BreathingPhase.emptyHold:
        return emptyHold;
    }
  }
}

class _CustomProtocolSettings {
  final _CustomProtocolInputMode inputMode;
  final _ProtocolPhaseValues phaseValues;
  final double cycleSeconds;
  final int sessionMinutes;

  const _CustomProtocolSettings({
    required this.inputMode,
    required this.phaseValues,
    required this.cycleSeconds,
    required this.sessionMinutes,
  });

  BreathingProtocol get protocol {
    if (inputMode == _CustomProtocolInputMode.ratio) {
      return BreathingProtocol.fromRatios(
        inhale: phaseValues.inhale,
        hold: phaseValues.hold,
        exhale: phaseValues.exhale,
        emptyHold: phaseValues.emptyHold,
        cycleDuration: Duration(
          microseconds: (cycleSeconds * Duration.microsecondsPerSecond).round(),
        ),
      );
    }
    return BreathingProtocol(
      inhaleDuration: _secondsToDuration(phaseValues.inhale),
      holdDuration: _secondsToDuration(phaseValues.hold),
      exhaleDuration: _secondsToDuration(phaseValues.exhale),
      emptyHoldDuration: _secondsToDuration(phaseValues.emptyHold),
    );
  }

  _ProtocolPhaseValues get protocolPhaseSeconds {
    final resolved = protocol;
    return _ProtocolPhaseValues(
      inhale: _durationSeconds(resolved.inhaleDuration),
      hold: _durationSeconds(resolved.holdDuration),
      exhale: _durationSeconds(resolved.exhaleDuration),
      emptyHold: _durationSeconds(resolved.emptyHoldDuration),
    );
  }
}

Map<BreathingPhase, TextEditingController> _phaseControllers(
  _ProtocolPhaseValues values,
) => {
  for (final phase in BreathingPhase.values)
    phase: TextEditingController(
      text: _formatProtocolValue(values.valueFor(phase)),
    ),
};

Duration _secondsToDuration(double seconds) =>
    Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());

double _durationSeconds(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerSecond;

String _formatProtocolValue(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String _formatProtocolDuration(Duration duration) =>
    '${_formatProtocolValue(_durationSeconds(duration))}s';

class _ProtocolPhaseField extends StatelessWidget {
  final BreathingPhase phase;
  final TextEditingController controller;
  final String suffix;
  final VoidCallback onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ProtocolPhaseField({
    required this.phase,
    required this.controller,
    required this.suffix,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _protocolPhaseColor(phase);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(_protocolPhaseIcon(phase), size: 19, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _protocolPhaseEditorLabel(phase),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _ProtocolStepButton(
          tooltip: 'Decrease ${phase.label.toLowerCase()}',
          icon: Icons.remove_rounded,
          onPressed: onDecrease,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 58,
          height: 40,
          child: TextField(
            key: ValueKey('custom-${phase.name}-input'),
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [_ProtocolNumberFormatter()],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 28,
          child: Text(suffix, style: Theme.of(context).textTheme.labelSmall),
        ),
        _ProtocolStepButton(
          tooltip: 'Increase ${phase.label.toLowerCase()}',
          icon: Icons.add_rounded,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _ProtocolRatioPairField extends StatelessWidget {
  final String label;
  final TextEditingController leftController;
  final TextEditingController rightController;
  final Key leftKey;
  final Key rightKey;
  final VoidCallback onChanged;

  const _ProtocolRatioPairField({
    required this.label,
    required this.leftController,
    required this.rightController,
    required this.leftKey,
    required this.rightKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget ratioInput({
      required Key key,
      required TextEditingController controller,
    }) {
      return SizedBox(
        width: 82,
        height: 42,
        child: TextField(
          key: key,
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [_ProtocolNumberFormatter()],
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            isDense: true,
            hintText: '0',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label =',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ratioInput(key: leftKey, controller: leftController),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                ':',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ratioInput(key: rightKey, controller: rightController),
          ],
        ),
      ],
    );
  }
}

class _ProtocolNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final VoidCallback onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ProtocolNumberField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _ProtocolStepButton(
          tooltip: 'Decrease $label',
          icon: Icons.remove_rounded,
          onPressed: onDecrease,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 64,
          height: 40,
          child: TextField(
            key: const ValueKey('custom-cycle-input'),
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [_ProtocolNumberFormatter()],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 28,
          child: Text(suffix, style: Theme.of(context).textTheme.labelSmall),
        ),
        _ProtocolStepButton(
          tooltip: 'Increase $label',
          icon: Icons.add_rounded,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _ProtocolStepButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ProtocolStepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProtocolSummary extends StatelessWidget {
  final BreathingProtocol protocol;

  const _ProtocolSummary({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cycleSeconds = _durationSeconds(protocol.cycleDuration);
    final rate = 60 / cycleSeconds;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.clinicalTeal.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.clinicalTeal.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 7,
            children: [
              for (final phase in BreathingPhase.values)
                _ProtocolSummaryItem(
                  phase: phase,
                  duration: protocol.durationFor(phase),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_formatProtocolValue(cycleSeconds)}s cycle  |  '
            '${rate.toStringAsFixed(1)} breaths/min',
            style: AppTheme.monoNumeral(
              color: AppTheme.clinicalTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolSummaryItem extends StatelessWidget {
  final BreathingPhase phase;
  final Duration duration;

  const _ProtocolSummaryItem({required this.phase, required this.duration});

  @override
  Widget build(BuildContext context) {
    final isDisabled = duration == Duration.zero;
    final color =
        isDisabled
            ? AppTheme.muted(Theme.of(context).brightness == Brightness.dark)
            : _protocolPhaseColor(phase);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_protocolPhaseIcon(phase), size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          _formatProtocolDuration(duration),
          style: AppTheme.monoNumeral(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProtocolNumberFormatter extends TextInputFormatter {
  const _ProtocolNumberFormatter();

  static final _pattern = RegExp(r'^\d{0,3}(?:\.\d?)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _pattern.hasMatch(newValue.text) ? newValue : oldValue;
}

String _protocolPhaseEditorLabel(BreathingPhase phase) {
  switch (phase) {
    case BreathingPhase.inhale:
      return 'Inspiration';
    case BreathingPhase.hold:
      return 'Post-inspiratory pause';
    case BreathingPhase.exhale:
      return 'Expiration';
    case BreathingPhase.emptyHold:
      return 'Post-expiratory pause';
  }
}

IconData _protocolPhaseIcon(BreathingPhase phase) {
  switch (phase) {
    case BreathingPhase.inhale:
      return Icons.arrow_upward_rounded;
    case BreathingPhase.hold:
      return Icons.pause_rounded;
    case BreathingPhase.exhale:
      return Icons.arrow_downward_rounded;
    case BreathingPhase.emptyHold:
      return Icons.hourglass_empty_rounded;
  }
}

Color _protocolPhaseColor(BreathingPhase phase) {
  switch (phase) {
    case BreathingPhase.inhale:
      return AppTheme.clinicalTeal;
    case BreathingPhase.hold:
    case BreathingPhase.emptyHold:
      return AppTheme.clinicalCyan;
    case BreathingPhase.exhale:
      return AppTheme.cardiacRose;
  }
}

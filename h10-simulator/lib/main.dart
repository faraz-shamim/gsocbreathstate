import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'simulator_controller.dart';
import 'simulator_preset.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulatorController()..initialize(),
      child: const BreathStateBleSimulatorApp(),
    ),
  );
}

class BreathStateBleSimulatorApp extends StatelessWidget {
  const BreathStateBleSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00A896),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BreathState BLE Sim',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0x1F12312D)),
          ),
        ),
      ),
      home: const SimulatorHomePage(),
    );
  }
}

class SimulatorHomePage extends StatelessWidget {
  const SimulatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulatorController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('BreathState BLE Sim'),
            actions: [
              Tooltip(
                message: 'Stop',
                child: IconButton(
                  onPressed: controller.isAdvertising
                      ? controller.stopAdvertising
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final content = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(flex: 6, child: _ControlColumn()),
                          SizedBox(width: 16),
                          Expanded(flex: 4, child: _LogPanel()),
                        ],
                      )
                    : const Column(
                        children: [
                          _ControlColumn(),
                          SizedBox(height: 16),
                          _LogPanel(),
                        ],
                      );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: content,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ControlColumn extends StatelessWidget {
  const _ControlColumn();

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulatorController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusPanel(controller: controller),
            const SizedBox(height: 16),
            _PresetPanel(controller: controller),
            const SizedBox(height: 16),
            _SignalPanel(controller: controller),
            const SizedBox(height: 16),
            _FaultPanel(controller: controller),
          ],
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final SimulatorController controller;

  const _StatusPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, controller.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth_audio, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    SimulatorController.localName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusPill(label: controller.statusLabel, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const _UuidChip(label: 'HR 180D'),
                const _UuidChip(label: 'PMD FB005C80'),
                _UuidChip(
                  label: controller.isEcgStreaming ? 'ECG live' : 'ECG 130 Hz',
                  active: controller.isEcgStreaming,
                ),
                _UuidChip(
                  label: controller.isAccStreaming ? 'ACC live' : 'ACC 200 Hz',
                  active: controller.isAccStreaming,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.canStart
                        ? controller.startAdvertising
                        : null,
                    icon: const Icon(Icons.sensors),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.canStop
                        ? controller.stopAdvertising
                        : null,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            if (controller.statusDetail != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.statusDetail!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, SimulatorStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case SimulatorStatus.ready:
      case SimulatorStatus.advertising:
      case SimulatorStatus.connected:
      case SimulatorStatus.streaming:
        return const Color(0xFF00856F);
      case SimulatorStatus.checkingPermissions:
        return const Color(0xFFB7791F);
      case SimulatorStatus.permissionsMissing:
      case SimulatorStatus.unsupported:
      case SimulatorStatus.error:
        return scheme.error;
      case SimulatorStatus.idle:
        return scheme.outline;
    }
  }
}

class _PresetPanel extends StatelessWidget {
  final SimulatorController controller;

  const _PresetPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preset', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SimulatorPreset.all.map((preset) {
                final selected = preset.id == controller.presetId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(preset.label),
                  avatar: selected ? const Icon(Icons.check, size: 16) : null,
                  onSelected: (_) => controller.applyPreset(preset.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  final SimulatorController controller;

  const _SignalPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _SimulatorSlider(
              label: 'Heart rate',
              value: controller.heartRateBpm,
              min: 40,
              max: 180,
              divisions: 140,
              unit: 'bpm',
              onChanged: controller.setHeartRate,
            ),
            _SimulatorSlider(
              label: 'Breathing rate',
              value: controller.breathRateBpm,
              min: 4,
              max: 30,
              divisions: 260,
              unit: 'bpm',
              fractionDigits: 1,
              onChanged: controller.setBreathRate,
            ),
            _SimulatorSlider(
              label: 'RSA amplitude',
              value: controller.rsaAmplitudeMs,
              min: 0,
              max: 150,
              divisions: 150,
              unit: 'ms',
              onChanged: controller.setRsaAmplitude,
            ),
            _SimulatorSlider(
              label: 'ECG noise',
              value: controller.ecgNoiseUv,
              min: 0,
              max: 150,
              divisions: 150,
              unit: 'uV',
              onChanged: controller.setEcgNoise,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaultPanel extends StatelessWidget {
  final SimulatorController controller;

  const _FaultPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faults', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _SimulatorSlider(
              label: 'Packet drop',
              value: controller.packetDropPercent,
              min: 0,
              max: 30,
              divisions: 30,
              unit: '%',
              onChanged: controller.setPacketDrop,
            ),
            _SimulatorSlider(
              label: 'Motion',
              value: controller.motionLevel,
              min: 0,
              max: 1,
              divisions: 100,
              unit: '',
              fractionDigits: 2,
              onChanged: controller.setMotionLevel,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ectopy'),
              value: controller.ectopyEnabled,
              onChanged: controller.setEctopyEnabled,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: controller.isAdvertising
                    ? controller.simulateDisconnect
                    : null,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulatorController>(
      builder: (context, controller, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Event Log',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Tooltip(
                      message: 'Clear log',
                      child: IconButton(
                        onPressed: controller.logs.isEmpty
                            ? null
                            : controller.clearLogs,
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 260),
                  child: controller.logs.isEmpty
                      ? const Text('No events')
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.logs.length,
                          separatorBuilder: (_, _) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            return Text(
                              controller.logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SimulatorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final int fractionDigits;
  final ValueChanged<double> onChanged;

  const _SimulatorSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    this.fractionDigits = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value.toStringAsFixed(fractionDigits);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                unit.isEmpty ? formatted : '$formatted $unit',
                style: const TextStyle(fontFeatures: []),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: unit.isEmpty ? formatted : '$formatted $unit',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _UuidChip extends StatelessWidget {
  final String label;
  final bool active;

  const _UuidChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF00856F)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: active ? 0.16 : 0.08),
        border: active
            ? Border.all(color: color.withValues(alpha: 0.45))
            : null,
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

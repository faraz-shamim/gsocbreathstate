// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BreathingSoundToggle extends StatelessWidget {
  final bool compact;
  final Future<void> Function()? onCueSettingsChanged;

  const BreathingSoundToggle({
    super.key,
    this.compact = false,
    this.onCueSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sound = context.watch<BreathingSoundProvider>();
    final enabled = sound.isEnabled;
    final icon = enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded;
    final tooltip = enabled ? 'Audio options' : 'Enable exercise audio';

    if (compact) {
      return Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed:
              () => showBreathingAudioSelector(
                context,
                onCueSettingsChanged: onCueSettingsChanged,
              ),
          icon: Icon(icon),
          color:
              enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed:
          () => showBreathingAudioSelector(
            context,
            onCueSettingsChanged: onCueSettingsChanged,
          ),
      icon: Icon(icon, size: 18),
      label: const Text('Audio'),
    );
  }
}

Future<void> showBreathingAudioSelector(
  BuildContext context, {
  Future<void> Function()? onCueSettingsChanged,
}) {
  return showDialog<void>(
    context: context,
    builder:
        (_) => _BreathingAudioSelectorDialog(
          onCueSettingsChanged: onCueSettingsChanged,
        ),
  );
}

class _BreathingAudioSelectorDialog extends StatelessWidget {
  final Future<void> Function()? onCueSettingsChanged;

  const _BreathingAudioSelectorDialog({this.onCueSettingsChanged});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 680),
        child: Consumer<BreathingSoundProvider>(
          builder: (context, sound, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercise audio',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: sound.isEnabled,
                    onChanged:
                        (value) => unawaited(() async {
                          await sound.setEnabled(
                            value,
                            previewCue: onCueSettingsChanged == null,
                          );
                          await onCueSettingsChanged?.call();
                        }()),
                    secondary: Icon(
                      sound.isEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                    ),
                    title: const Text('Audio enabled'),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Breathing cue',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<BreathingGuideSound>(
                    segments: const [
                      ButtonSegment<BreathingGuideSound>(
                        value: BreathingGuideSound.metronome,
                        icon: Icon(Icons.music_note_rounded),
                        label: Text('Metronome'),
                      ),
                      ButtonSegment<BreathingGuideSound>(
                        value: BreathingGuideSound.hum,
                        icon: Icon(Icons.graphic_eq_rounded),
                        label: Text('Hum'),
                      ),
                    ],
                    selected: <BreathingGuideSound>{sound.guide},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      unawaited(() async {
                        await sound.setGuide(
                          selection.first,
                          previewCue: onCueSettingsChanged == null,
                        );
                        await onCueSettingsChanged?.call();
                      }());
                    },
                  ),
                  const Divider(height: 32),
                  Text(
                    'Background ambience',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _AmbienceOption(
                    ambience: BreathingAmbience.river,
                    title: 'River',
                    icon: Icons.water_rounded,
                    selected: sound.ambience.contains(BreathingAmbience.river),
                    onChanged: sound.toggleAmbience,
                  ),
                  _AmbienceOption(
                    ambience: BreathingAmbience.rainyBirds,
                    title: 'Rainy birds',
                    icon: Icons.forest_rounded,
                    selected: sound.ambience.contains(
                      BreathingAmbience.rainyBirds,
                    ),
                    onChanged: sound.toggleAmbience,
                  ),
                  _AmbienceOption(
                    ambience: BreathingAmbience.rain,
                    title: 'Rain',
                    icon: Icons.grain_rounded,
                    selected: sound.ambience.contains(BreathingAmbience.rain),
                    onChanged: sound.toggleAmbience,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmbienceOption extends StatelessWidget {
  final BreathingAmbience ambience;
  final String title;
  final IconData icon;
  final bool selected;
  final Future<void> Function(BreathingAmbience) onChanged;

  const _AmbienceOption({
    required this.ambience,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
      value: selected,
      onChanged: (_) => unawaited(onChanged(ambience)),
      secondary: Icon(icon),
      title: Text(title),
    );
  }
}

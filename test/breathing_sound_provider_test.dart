// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sound guide persists its state and suppresses disabled cues', () async {
    final player = _FakeBreathingAudioPlayer();
    final provider = BreathingSoundProvider(player: player);

    await provider.initialize();
    expect(provider.isEnabled, isTrue);

    await provider.prepareForSession();
    await provider.cue(BreathingCue.exhale);
    expect(player.primeCount, 1);
    expect(player.cues.map((cue) => cue.cue), [BreathingCue.exhale]);
    expect(player.cues.single.guide, BreathingGuideSound.metronome);

    await provider.setEnabled(false);
    await provider.cue(BreathingCue.inhale);
    expect(player.cues.map((cue) => cue.cue), [BreathingCue.exhale]);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(BreathingSoundProvider.preferenceKey), isFalse);

    await provider.setEnabled(true);
    expect(player.cues.map((cue) => cue.cue), [
      BreathingCue.exhale,
      BreathingCue.inhale,
    ]);
  });

  test('sound guide restores a disabled preference', () async {
    SharedPreferences.setMockInitialValues({
      BreathingSoundProvider.preferenceKey: false,
    });
    final provider = BreathingSoundProvider(
      player: _FakeBreathingAudioPlayer(),
    );

    await provider.initialize();

    expect(provider.isEnabled, isFalse);
  });

  test('supports layered ambience and keeps metronome above its mix', () async {
    final player = _FakeBreathingAudioPlayer();
    final provider = BreathingSoundProvider(player: player);
    await provider.initialize();

    await provider.toggleAmbience(BreathingAmbience.river);
    await provider.toggleAmbience(BreathingAmbience.rain);
    expect(player.ambience, isEmpty);

    await provider.beginSession();
    expect(player.ambience, {BreathingAmbience.river, BreathingAmbience.rain});
    expect(player.ambienceVolume, 0.24);

    await provider.cue(BreathingCue.inhale);
    expect(player.cues.single.guide, BreathingGuideSound.metronome);
    expect(player.cues.single.volume, greaterThan(player.ambienceVolume));

    await provider.endSession();
    expect(player.ambience, isEmpty);
    expect(player.stopCount, greaterThan(0));

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList(BreathingSoundProvider.ambiencePreferenceKey),
      containsAll(<String>['river', 'rain']),
    );
  });

  test('hum selection is persisted and used for phase cues', () async {
    final player = _FakeBreathingAudioPlayer();
    final provider = BreathingSoundProvider(player: player);
    await provider.initialize();

    await provider.setGuide(BreathingGuideSound.hum);
    await provider.cue(
      BreathingCue.exhale,
      sustainFor: const Duration(seconds: 6),
    );

    expect(player.cues.last.guide, BreathingGuideSound.hum);
    expect(player.cues.last.volume, 0.82);
    expect(player.cues.last.sustainFor, const Duration(seconds: 6));

    final cueCountBeforeHold = player.cues.length;
    final stopCountBeforeHold = player.stopCueCount;
    await provider.repeatCueForHold(
      BreathingCue.exhale,
      duration: const Duration(seconds: 7),
    );
    expect(player.cues, hasLength(cueCountBeforeHold + 1));
    expect(player.cues.last.cue, BreathingCue.hold);
    expect(player.cues.last.guide, BreathingGuideSound.hum);
    expect(player.cues.last.sustainFor, const Duration(seconds: 7));
    expect(player.stopCueCount, stopCountBeforeHold);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(BreathingSoundProvider.guidePreferenceKey),
      'hum',
    );
  });

  test('hold phases replay metronome as a one-shot cue', () async {
    final player = _FakeBreathingAudioPlayer();
    final provider = BreathingSoundProvider(player: player);
    await provider.initialize();

    await provider.repeatCueForHold(
      BreathingCue.inhale,
      duration: const Duration(seconds: 4),
    );

    expect(player.cues, hasLength(1));
    expect(player.cues.single.guide, BreathingGuideSound.metronome);
    expect(player.cues.single.sustainFor, isNull);
    expect(player.stopCueCount, 0);
  });

  test('cue previews can be suppressed for a phase-aware surface', () async {
    final player = _FakeBreathingAudioPlayer();
    final provider = BreathingSoundProvider(player: player);
    await provider.initialize();

    await provider.setEnabled(false);
    await provider.setEnabled(true, previewCue: false);
    expect(player.cues, isEmpty);

    await provider.setGuide(BreathingGuideSound.hum, previewCue: false);
    expect(player.cues, isEmpty);
    expect(player.stopCueCount, greaterThan(0));
  });
}

class _FakeBreathingAudioPlayer implements BreathingAudioPlayer {
  final List<_PlayedCue> cues = [];
  int primeCount = 0;
  int stopCount = 0;
  int stopCueCount = 0;
  Set<BreathingAmbience> ambience = <BreathingAmbience>{};
  double ambienceVolume = 0;

  @override
  Future<void> playCue(
    BreathingCue cue,
    BreathingGuideSound guide, {
    double volume = 0.58,
    Duration? sustainFor,
  }) async {
    cues.add(_PlayedCue(cue, guide, volume, sustainFor));
  }

  @override
  Future<void> prime(BreathingGuideSound guide) async {
    primeCount++;
  }

  @override
  Future<void> setAmbience(
    Set<BreathingAmbience> ambience, {
    required double volume,
  }) async {
    this.ambience = Set<BreathingAmbience>.from(ambience);
    ambienceVolume = volume;
  }

  @override
  Future<void> stopAmbience() async {
    stopCount++;
    ambience = <BreathingAmbience>{};
  }

  @override
  Future<void> stopCue() async {
    stopCueCount++;
  }

  @override
  Future<void> dispose() async {}
}

class _PlayedCue {
  final BreathingCue cue;
  final BreathingGuideSound guide;
  final double volume;
  final Duration? sustainFor;

  const _PlayedCue(this.cue, this.guide, this.volume, this.sustainFor);
}

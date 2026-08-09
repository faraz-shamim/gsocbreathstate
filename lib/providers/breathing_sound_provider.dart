import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BreathingCue { inhale, hold, exhale }

enum BreathingGuideSound { metronome, hum }

enum BreathingAmbience { river, rainyBirds, rain }

abstract interface class BreathingAudioPlayer {
  Future<void> playCue(
    BreathingCue cue,
    BreathingGuideSound guide, {
    double volume = 0.58,
    Duration? sustainFor,
  });

  Future<void> stopCue();

  Future<void> prime(BreathingGuideSound guide);

  Future<void> setAmbience(
    Set<BreathingAmbience> ambience, {
    required double volume,
  });

  Future<void> stopAmbience();

  Future<void> dispose();
}

class BreathingSoundProvider extends ChangeNotifier {
  static const preferenceKey = 'breathing_sound_guide_enabled';
  static const guidePreferenceKey = 'breathing_sound_guide_type';
  static const ambiencePreferenceKey = 'breathing_sound_ambience';

  final BreathingAudioPlayer _player;
  final Future<SharedPreferences> Function() _preferencesLoader;

  bool _isEnabled = true;
  BreathingGuideSound _guide = BreathingGuideSound.metronome;
  Set<BreathingAmbience> _ambience = <BreathingAmbience>{};
  int _activeSessionCount = 0;

  BreathingSoundProvider({
    BreathingAudioPlayer? player,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _player = player ?? FlutterSoundBreathingAudioPlayer(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  bool get isEnabled => _isEnabled;
  BreathingGuideSound get guide => _guide;
  Set<BreathingAmbience> get ambience => Set.unmodifiable(_ambience);

  Future<void> initialize() async {
    final preferences = await _preferencesLoader();
    _isEnabled = preferences.getBool(preferenceKey) ?? true;
    _guide =
        _enumByName(
          BreathingGuideSound.values,
          preferences.getString(guidePreferenceKey),
          BreathingGuideSound.metronome,
        ) ??
        BreathingGuideSound.metronome;
    _ambience =
        (preferences.getStringList(ambiencePreferenceKey) ?? const <String>[])
            .map(
              (name) => _enumByName<BreathingAmbience>(
                BreathingAmbience.values,
                name,
                null,
              ),
            )
            .whereType<BreathingAmbience>()
            .toSet();
  }

  Future<void> setEnabled(bool value, {bool previewCue = true}) async {
    if (_isEnabled == value) return;
    _isEnabled = value;
    notifyListeners();

    final preferences = await _preferencesLoader();
    await preferences.setBool(preferenceKey, value);

    if (value) {
      if (previewCue) {
        await cue(BreathingCue.inhale);
      }
      await _syncAmbience();
    } else {
      await Future.wait([_stopCue(), _stopAmbience()]);
    }
  }

  Future<void> setGuide(
    BreathingGuideSound value, {
    bool previewCue = true,
  }) async {
    if (_guide == value) return;
    _guide = value;
    notifyListeners();

    final preferences = await _preferencesLoader();
    await preferences.setString(guidePreferenceKey, value.name);
    await _stopCue();
    if (_isEnabled && previewCue) {
      await cue(BreathingCue.inhale);
    }
  }

  Future<void> toggleAmbience(BreathingAmbience value) async {
    final updated = Set<BreathingAmbience>.from(_ambience);
    if (!updated.add(value)) {
      updated.remove(value);
    }
    _ambience = updated;
    notifyListeners();

    final preferences = await _preferencesLoader();
    await preferences.setStringList(
      ambiencePreferenceKey,
      _ambience.map((item) => item.name).toList(growable: false),
    );
    await _syncAmbience();
  }

  Future<void> prepareForSession() async {
    if (!_isEnabled) return;
    try {
      await _player.prime(_guide);
    } catch (error) {
      debugPrint('Could not prime breathing audio: $error');
    }
  }

  Future<void> beginSession() async {
    _activeSessionCount++;
    if (_activeSessionCount > 1) return;
    await prepareForSession();
    await _syncAmbience();
  }

  Future<void> endSession() async {
    if (_activeSessionCount <= 0) return;
    _activeSessionCount--;
    if (_activeSessionCount == 0) {
      await Future.wait([_stopCue(), _stopAmbience()]);
    }
  }

  Future<void> cue(BreathingCue cue, {Duration? sustainFor}) async {
    if (!_isEnabled) return;
    final volume = switch (_guide) {
      BreathingGuideSound.metronome => _ambience.isEmpty ? 0.58 : 0.68,
      BreathingGuideSound.hum => 0.82,
    };
    try {
      await _player.playCue(
        cue,
        _guide,
        volume: volume,
        sustainFor: _guide == BreathingGuideSound.hum ? sustainFor : null,
      );
    } catch (error) {
      debugPrint('Could not play breathing cue: $error');
    }
  }

  Future<void> repeatCueForHold(
    BreathingCue metronomeCue, {
    required Duration duration,
  }) async {
    if (!_isEnabled) return;
    if (_guide == BreathingGuideSound.hum) {
      await cue(BreathingCue.hold, sustainFor: duration);
      return;
    }
    await cue(metronomeCue);
  }

  Future<void> _syncAmbience() async {
    if (!_isEnabled || _activeSessionCount == 0 || _ambience.isEmpty) {
      await _stopAmbience();
      return;
    }
    final volume = switch (_ambience.length) {
      1 => 0.32,
      2 => 0.24,
      _ => 0.20,
    };
    try {
      await _player.setAmbience(_ambience, volume: volume);
    } catch (error) {
      debugPrint('Could not update breathing ambience: $error');
    }
  }

  Future<void> _stopAmbience() async {
    try {
      await _player.stopAmbience();
    } catch (error) {
      debugPrint('Could not stop breathing ambience: $error');
    }
  }

  Future<void> _stopCue() async {
    try {
      await _player.stopCue();
    } catch (error) {
      debugPrint('Could not stop breathing cue: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }
}

T? _enumByName<T extends Enum>(List<T> values, String? name, T? fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class FlutterSoundBreathingAudioPlayer implements BreathingAudioPlayer {
  static const _cueAssets = <BreathingGuideSound, Map<BreathingCue, String>>{
    BreathingGuideSound.metronome: <BreathingCue, String>{
      BreathingCue.inhale: 'audio/inhale_cue.wav',
      BreathingCue.exhale: 'audio/exhale_cue.wav',
    },
    BreathingGuideSound.hum: <BreathingCue, String>{
      BreathingCue.inhale: 'audio/inhale_hum.wav',
      BreathingCue.hold: 'audio/hold_hum.wav',
      BreathingCue.exhale: 'audio/exhale_hum.wav',
    },
  };
  static const _ambienceAssets = <BreathingAmbience, String>{
    BreathingAmbience.river: 'river.mp3',
    BreathingAmbience.rainyBirds: 'rainy_birds.mp3',
    BreathingAmbience.rain: 'rain.mp3',
  };

  final Map<
    BreathingGuideSound,
    Map<BreathingCue, Future<_BreathingCueChannel>>
  >
  _cueChannelFutures =
      <BreathingGuideSound, Map<BreathingCue, Future<_BreathingCueChannel>>>{};
  final Map<BreathingGuideSound, Future<Map<BreathingCue, Uint8List>>>
  _cueDataFutures =
      <BreathingGuideSound, Future<Map<BreathingCue, Uint8List>>>{};
  final Map<BreathingAmbience, Future<_LoopingAudioChannel>> _ambienceChannels =
      <BreathingAmbience, Future<_LoopingAudioChannel>>{};
  final Set<BreathingAmbience> _activeAmbience = <BreathingAmbience>{};
  _BreathingCueChannel? _activeCueChannel;
  Future<void> _cueOperation = Future<void>.value();
  Future<void> _ambienceOperation = Future<void>.value();

  Future<_BreathingCueChannel> _loadCueChannel(
    BreathingGuideSound guide,
    BreathingCue cue,
  ) {
    final channels = _cueChannelFutures.putIfAbsent(
      guide,
      () => <BreathingCue, Future<_BreathingCueChannel>>{},
    );
    return channels.putIfAbsent(
      cue,
      () => _createCueChannel(guide, cue, channels),
    );
  }

  Future<_BreathingCueChannel> _createCueChannel(
    BreathingGuideSound guide,
    BreathingCue cue,
    Map<BreathingCue, Future<_BreathingCueChannel>> channels,
  ) async {
    try {
      return await _BreathingCueChannel.open();
    } catch (_) {
      channels.remove(cue);
      if (channels.isEmpty) {
        _cueChannelFutures.remove(guide);
      }
      rethrow;
    }
  }

  Future<Map<BreathingCue, Uint8List>> _loadCueData(BreathingGuideSound guide) {
    return _cueDataFutures.putIfAbsent(guide, () async {
      try {
        final assets = _cueAssets[guide]!;
        return <BreathingCue, Uint8List>{
          for (final entry in assets.entries)
            entry.key: await _loadAssetData(entry.value),
        };
      } catch (_) {
        _cueDataFutures.remove(guide);
        rethrow;
      }
    });
  }

  @override
  Future<void> playCue(
    BreathingCue cue,
    BreathingGuideSound guide, {
    double volume = 0.58,
    Duration? sustainFor,
  }) {
    final operation = _cueOperation.then(
      (_) => _activateCue(cue, guide, volume, sustainFor),
      onError: (_) => _activateCue(cue, guide, volume, sustainFor),
    );
    _cueOperation = operation;
    return operation;
  }

  Future<void> _activateCue(
    BreathingCue cue,
    BreathingGuideSound guide,
    double volume,
    Duration? sustainFor,
  ) async {
    final cueData = await _loadCueData(guide);
    final channel = await _loadCueChannel(guide, cue);
    final previousChannel = _activeCueChannel;
    if (previousChannel != null && previousChannel != channel) {
      await previousChannel.stop();
    }
    _activeCueChannel = channel;
    await channel.play(
      cueData[cue]!,
      volume: volume.clamp(0.0, 1.0).toDouble(),
      sustainFor: sustainFor,
    );
  }

  @override
  Future<void> stopCue() {
    final operation = _cueOperation.then(
      (_) => _stopActiveCue(),
      onError: (_) => _stopActiveCue(),
    );
    _cueOperation = operation;
    return operation;
  }

  Future<void> _stopActiveCue() async {
    final channel = _activeCueChannel;
    _activeCueChannel = null;
    await channel?.stop();
  }

  @override
  Future<void> prime(BreathingGuideSound guide) async {
    final cueData = await _loadCueData(guide);
    await Future.wait(cueData.keys.map((cue) => _loadCueChannel(guide, cue)));
  }

  @override
  Future<void> setAmbience(
    Set<BreathingAmbience> ambience, {
    required double volume,
  }) {
    final requested = Set<BreathingAmbience>.from(ambience);
    final operation = _ambienceOperation.then(
      (_) => _applyAmbience(requested, volume),
      onError: (_) => _applyAmbience(requested, volume),
    );
    _ambienceOperation = operation;
    return operation;
  }

  Future<void> _applyAmbience(
    Set<BreathingAmbience> requested,
    double volume,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    void rememberError(Object error, StackTrace stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    final removed = _activeAmbience.difference(requested);
    for (final ambience in removed) {
      final channelFuture = _ambienceChannels[ambience];
      try {
        final channel = await channelFuture;
        await channel?.stop();
      } catch (error, stackTrace) {
        _ambienceChannels.remove(ambience);
        rememberError(error, stackTrace);
      } finally {
        _activeAmbience.remove(ambience);
      }
    }

    for (final ambience in requested) {
      final channelFuture =
          _ambienceChannels[ambience] ??= _LoopingAudioChannel.open(
            assetPath: _ambienceAssets[ambience]!,
            codec: Codec.mp3,
          );
      _LoopingAudioChannel? channel;
      try {
        channel = await channelFuture;
        await channel.start(volume: volume);
        _activeAmbience.add(ambience);
      } catch (error, stackTrace) {
        if (channel == null) {
          _ambienceChannels.remove(ambience);
        } else {
          try {
            await channel.stop();
          } catch (_) {}
        }
        _activeAmbience.remove(ambience);
        rememberError(error, stackTrace);
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  @override
  Future<void> stopAmbience() {
    final operation = _ambienceOperation.then(
      (_) => _applyAmbience(<BreathingAmbience>{}, 0),
      onError: (_) => _applyAmbience(<BreathingAmbience>{}, 0),
    );
    _ambienceOperation = operation;
    return operation;
  }

  @override
  Future<void> dispose() async {
    await stopCue();
    await stopAmbience();

    for (final channels in _cueChannelFutures.values) {
      for (final channelFuture in channels.values) {
        try {
          final channel = await channelFuture;
          await channel.dispose();
        } catch (_) {}
      }
    }

    for (final channelFuture in _ambienceChannels.values) {
      try {
        final channel = await channelFuture;
        await channel.dispose();
      } catch (_) {}
    }
  }
}

Future<Uint8List> _loadAssetData(String assetPath) async {
  final data = await rootBundle.load('assets/$assetPath');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

class _BreathingCueChannel {
  final FlutterSoundPlayer _player;
  Future<void> _playbackOperation = Future<void>.value();
  Timer? _stopTimer;
  int _generation = 0;

  _BreathingCueChannel(this._player);

  static Future<_BreathingCueChannel> open() async {
    final player = FlutterSoundPlayer();
    await player.openPlayer();
    return _BreathingCueChannel(player);
  }

  Future<void> play(
    Uint8List audioData, {
    required double volume,
    Duration? sustainFor,
  }) {
    final generation = ++_generation;
    _stopTimer?.cancel();
    final operation = _playbackOperation.then(
      (_) => _play(audioData, volume, sustainFor, generation),
      onError: (_) => _play(audioData, volume, sustainFor, generation),
    );
    _playbackOperation = operation;
    return operation;
  }

  Future<void> _play(
    Uint8List audioData,
    double volume,
    Duration? sustainFor,
    int generation,
  ) async {
    if (generation != _generation) return;
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
    if (generation != _generation) return;
    await _player.setVolume(volume);
    if (generation != _generation) return;
    await _player.startPlayer(fromDataBuffer: audioData, codec: Codec.pcm16WAV);
    if (generation == _generation && sustainFor != null) {
      _stopTimer = Timer(
        sustainFor,
        () => unawaited(stop(expectedGeneration: generation)),
      );
    }
  }

  Future<void> stop({int? expectedGeneration}) {
    if (expectedGeneration != null && expectedGeneration != _generation) {
      return Future<void>.value();
    }
    _generation++;
    _stopTimer?.cancel();
    _stopTimer = null;
    final operation = _playbackOperation.then(
      (_) => _stopPlayback(),
      onError: (_) => _stopPlayback(),
    );
    _playbackOperation = operation;
    return operation;
  }

  Future<void> _stopPlayback() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  Future<void> dispose() async {
    _generation++;
    _stopTimer?.cancel();
    try {
      await _playbackOperation;
    } catch (_) {}
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
    await _player.closePlayer();
  }
}

class _LoopingAudioChannel {
  final FlutterSoundPlayer _player;
  final Uint8List _audioData;
  final Codec _codec;

  bool _shouldLoop = false;
  double _volume = 0;
  int _generation = 0;

  _LoopingAudioChannel(this._player, this._audioData, this._codec);

  static Future<_LoopingAudioChannel> open({
    required String assetPath,
    required Codec codec,
  }) async {
    final data = await rootBundle.load('assets/$assetPath');
    final audioData = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final player = FlutterSoundPlayer();
    await player.openPlayer();
    return _LoopingAudioChannel(player, audioData, codec);
  }

  Future<void> start({required double volume}) async {
    _shouldLoop = true;
    _volume = volume.clamp(0.0, 1.0).toDouble();
    if (_player.isPlaying) {
      await _player.setVolume(_volume);
      return;
    }
    final generation = ++_generation;
    await _startPlayback(generation);
  }

  Future<void> _startPlayback(int generation) async {
    if (!_shouldLoop || generation != _generation) return;
    await _player.setVolume(_volume);
    if (!_shouldLoop || generation != _generation) return;
    await _player.startPlayer(
      fromDataBuffer: _audioData,
      codec: _codec,
      whenFinished: () {
        if (_shouldLoop && generation == _generation) {
          unawaited(_startPlayback(generation));
        }
      },
    );
  }

  Future<void> stop() async {
    _shouldLoop = false;
    _generation++;
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _player.closePlayer();
  }
}

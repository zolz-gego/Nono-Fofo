import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/audio_engine.dart';

/// [AudioEngine] backed by the `audioplayers` package.
/// Effects use a small round-robin pool so they can overlap.
class AudioplayersAudioEngine implements AudioEngine {
  AudioplayersAudioEngine({this.effectPoolSize = 8});

  final int effectPoolSize;
  final List<AudioPlayer> _effects = [];
  late final AudioPlayer _voice;
  late final AudioPlayer _music;
  int _next = 0;
  String? _currentMusic;

  /// AssetSource paths are relative to the `assets/` folder.
  static Source _src(String assetPath) =>
      AssetSource(assetPath.replaceFirst(RegExp(r'^assets/'), ''));

  @override
  Future<void> init() async {
    final mode = kIsWeb ? PlayerMode.mediaPlayer : PlayerMode.lowLatency;
    for (var i = 0; i < effectPoolSize; i++) {
      final p = AudioPlayer(playerId: 'sfx_$i');
      await p.setPlayerMode(mode);
      await p.setReleaseMode(ReleaseMode.stop);
      _effects.add(p);
    }
    _voice = AudioPlayer(playerId: 'voice');
    await _voice.setReleaseMode(ReleaseMode.stop);
    _music = AudioPlayer(playerId: 'music');
  }

  @override
  Future<void> playEffect(String assetPath, {double volume = 1}) async {
    if (_effects.isEmpty || volume <= 0) return;
    final player = _effects[_next];
    _next = (_next + 1) % _effects.length;
    await _guard(() async {
      await player.stop();
      await player.play(_src(assetPath), volume: volume);
    });
  }

  @override
  Future<void> playVoice(String assetPath, {double volume = 1}) async {
    if (volume <= 0) return;
    await _guard(() async {
      await _voice.stop();
      await _voice.play(_src(assetPath), volume: volume);
    });
  }

  @override
  Future<void> playMusic(String assetPath,
      {double volume = 1, bool loop = true}) async {
    if (_currentMusic == assetPath && _music.state == PlayerState.playing) {
      return setMusicVolume(volume);
    }
    _currentMusic = assetPath;
    await _guard(() async {
      await _fade(_music.volume, 0);
      await _music.stop();
      await _music.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _music.play(_src(assetPath), volume: 0);
      await _fade(0, volume);
    });
  }

  @override
  Future<void> setMusicVolume(double volume) =>
      _guard(() => _music.setVolume(volume));

  @override
  Future<void> stopMusic() async {
    _currentMusic = null;
    await _guard(() async {
      await _fade(_music.volume, 0);
      await _music.stop();
    });
  }

  @override
  Future<void> pauseAll() => _guard(() async {
        await _music.pause();
        await _voice.pause();
      });

  @override
  Future<void> resumeAll() => _guard(() async {
        if (_currentMusic != null) await _music.resume();
      });

  @override
  Future<void> dispose() async {
    for (final p in [..._effects, _voice, _music]) {
      await p.dispose();
    }
    _effects.clear();
  }

  Future<void> _fade(double from, double to,
      {Duration duration = const Duration(milliseconds: 400)}) async {
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await _music.setVolume(from + (to - from) * i / steps);
      await Future<void>.delayed(duration ~/ steps);
    }
  }

  /// Sound must never crash the app (e.g. browser autoplay blocks before the
  /// first tap); failures are logged and ignored.
  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[audio] $e');
    }
  }
}

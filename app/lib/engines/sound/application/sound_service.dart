import 'dart:math';

import '../../../core/domain/character_id.dart';
import '../domain/audio_engine.dart';
import '../domain/sound_catalog.dart';
import '../domain/sound_event.dart';
import '../domain/sound_repository.dart';

/// The one entry point for sound in the app.
///
/// ```dart
/// sound.play(SoundEvent.correctAnswer, by: CharacterId.nono);
/// sound.playKey('fishing.fish_catch');
/// sound.playMusic(MusicTrack.nile);
/// ```
class SoundService {
  SoundService(this._repository, this._engine, {Random? random})
      : _random = random ?? Random();

  final SoundRepository _repository;
  final AudioEngine _engine;
  final Random _random;

  SoundCatalog _catalog = SoundCatalog.empty;
  final Map<String, String> _lastPicked = {};
  MusicTrack? _currentTrack;

  double _sfxVolume = 1;
  double _voiceVolume = 1;
  double _musicVolume = 0.5;
  bool _muted = false;

  SoundCatalog get catalog => _catalog;
  MusicTrack? get currentTrack => _currentTrack;

  Future<void> init() async {
    await _engine.init();
    _catalog = await _repository.loadCatalog();
  }

  /// Plays the effect (and the brother's voice, if [by] is given and the
  /// event has one) mapped to [event] in sound_map.json.
  Future<void> play(SoundEvent event, {CharacterId? by}) =>
      playKey(event.key, by: by);

  /// Same as [play] for string keys, used by games (`"<game>.<sound>"`).
  Future<void> playKey(String key, {CharacterId? by}) async {
    if (_muted) return;
    final cue = _catalog.cues[key];
    if (cue == null) return;

    final sfxId = _pick(key, cue.sfx);
    final sfxPath = sfxId == null ? null : _catalog.sfxPath(sfxId);
    if (sfxPath != null) _engine.playEffect(sfxPath, volume: _sfxVolume);

    if (by != null) await playVoice(by, cue.voice[by] ?? const [], key: key);
  }

  /// Plays one of [ids] in the brother's voice.
  Future<void> playVoice(CharacterId who, List<String> ids, {String? key}) async {
    if (_muted) return;
    final id = _pick('${key ?? ids.join()}#${who.name}', ids);
    final path = id == null ? null : _catalog.voicePath(who, id);
    if (path != null) await _engine.playVoice(path, volume: _voiceVolume);
  }

  /// Plays a single effect by its manifest id (sound board / previews).
  Future<void> previewSfx(String id) async {
    final path = _catalog.sfxPath(id);
    if (path != null) await _engine.playEffect(path, volume: _sfxVolume);
  }

  Future<void> playMusic(MusicTrack track) async {
    _currentTrack = track;
    if (_muted) return;
    final id = _catalog.musicSlots[track.key];
    final path = id == null ? null : _catalog.musicPath(id);
    if (path != null) await _engine.playMusic(path, volume: _musicVolume);
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    await _engine.stopMusic();
  }

  Future<void> applySettings({
    required double sfx,
    required double voice,
    required double music,
    required bool muted,
  }) async {
    final wasMuted = _muted;
    _sfxVolume = sfx;
    _voiceVolume = voice;
    _musicVolume = music;
    _muted = muted;
    if (muted) {
      await _engine.setMusicVolume(0);
    } else if (wasMuted && _currentTrack != null) {
      await playMusic(_currentTrack!);
    } else {
      await _engine.setMusicVolume(music);
    }
  }

  Future<void> pause() => _engine.pauseAll();
  Future<void> resume() => _engine.resumeAll();

  /// Random pick that avoids repeating the previous choice for the same key.
  String? _pick(String key, List<String> ids) {
    if (ids.isEmpty) return null;
    if (ids.length == 1) return ids.first;
    final options = ids.where((id) => id != _lastPicked[key]).toList();
    final id = options[_random.nextInt(options.length)];
    _lastPicked[key] = id;
    return id;
  }
}

import 'package:equatable/equatable.dart';

import '../../../core/domain/character_id.dart';

/// What to play for one event: a pool of effects and, optionally, a pool of
/// voice clips per brother.
class SoundCue extends Equatable {
  const SoundCue({this.sfx = const [], this.voice = const {}});

  final List<String> sfx;
  final Map<CharacterId, List<String>> voice;

  @override
  List<Object?> get props => [sfx, voice];
}

/// Everything the sound service needs: cues per event key, music slots, and
/// resolved asset paths for every sound id.
class SoundCatalog {
  const SoundCatalog({
    required this.cues,
    required this.musicSlots,
    required this.sfxPaths,
    required this.voicePaths,
    required this.musicPaths,
  });

  static const empty = SoundCatalog(
      cues: {}, musicSlots: {}, sfxPaths: {}, voicePaths: {}, musicPaths: {});

  final Map<String, SoundCue> cues;
  final Map<String, String> musicSlots;
  final Map<String, String> sfxPaths;
  final Map<CharacterId, Map<String, String>> voicePaths;
  final Map<String, String> musicPaths;

  String? sfxPath(String id) => sfxPaths[id];
  String? voicePath(CharacterId c, String id) => voicePaths[c]?[id];
  String? musicPath(String id) => musicPaths[id];
}

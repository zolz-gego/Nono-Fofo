import 'package:flutter/foundation.dart';

import '../../../core/assets/asset_paths.dart';
import '../../../core/assets/json_asset_loader.dart';
import '../../../core/domain/character_id.dart';
import '../domain/sound_catalog.dart';
import '../domain/sound_repository.dart';

/// Builds the [SoundCatalog] from `assets/audio/manifest.json` (written by the
/// audio pipelines) and `assets/audio/sound_map.json` (edited by hand).
class SoundRepositoryImpl implements SoundRepository {
  const SoundRepositoryImpl(this._loader);

  final JsonAssetLoader _loader;

  @override
  Future<SoundCatalog> loadCatalog() async {
    final manifest = await _loader.load(AssetPaths.audioManifest);
    final map = await _loader.load(AssetPaths.soundMap);

    String full(String file) => '${AssetPaths.audio}/$file';

    final sfxPaths = <String, String>{
      for (final e in _section(manifest, 'sfx').entries)
        e.key: full((e.value as Map)['file'] as String),
    };
    final musicPaths = <String, String>{
      for (final e in _section(manifest, 'music').entries)
        if ((e.value as Map)['status'] != 'missing')
          e.key: full((e.value as Map)['file'] as String),
    };
    final voiceSection = _section(manifest, 'voice');
    final voicePaths = <CharacterId, Map<String, String>>{
      for (final c in CharacterId.values)
        c: {
          for (final e in _section(voiceSection, c.name).entries)
            if ((e.value as Map)['status'] != 'missing')
              e.key: full((e.value as Map)['file'] as String),
        },
    };

    final cues = <String, SoundCue>{};
    for (final e in _section(map, 'events').entries) {
      final raw = e.value as Map<String, dynamic>;
      final voiceRaw = (raw['voice'] as Map<String, dynamic>?) ?? const {};
      cues[e.key] = SoundCue(
        sfx: _strings(raw['sfx']),
        voice: {
          for (final c in CharacterId.values)
            if (voiceRaw[c.name] != null) c: _strings(voiceRaw[c.name]),
        },
      );
    }
    final musicSlots = _section(
      map,
      'music',
    ).map((k, v) => MapEntry(k, v as String));

    final catalog = SoundCatalog(
      cues: cues,
      musicSlots: musicSlots,
      sfxPaths: sfxPaths,
      voicePaths: voicePaths,
      musicPaths: musicPaths,
    );
    if (kDebugMode) _reportBrokenReferences(catalog);
    return catalog;
  }

  static Map<String, dynamic> _section(Map<String, dynamic> json, String key) =>
      (json[key] as Map<String, dynamic>?) ?? const {};

  static List<String> _strings(Object? v) =>
      (v as List<dynamic>? ?? const []).cast<String>();

  /// Logs sound_map ids that don't exist in the manifest, so typos in the
  /// JSON are caught during development instead of failing silently.
  static void _reportBrokenReferences(SoundCatalog c) {
    for (final e in c.cues.entries) {
      for (final id in e.value.sfx) {
        if (c.sfxPath(id) == null) {
          debugPrint('[sound_map] "${e.key}": unknown sfx "$id"');
        }
      }
      e.value.voice.forEach((ch, ids) {
        for (final id in ids) {
          if (c.voicePath(ch, id) == null) {
            debugPrint(
              '[sound_map] "${e.key}": unknown ${ch.name} voice "$id"',
            );
          }
        }
      });
    }
    c.musicSlots.forEach((slot, id) {
      if (c.musicPath(id) == null) {
        debugPrint('[sound_map] music "$slot": unknown music "$id"');
      }
    });
  }
}

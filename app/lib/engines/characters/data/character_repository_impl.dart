import 'dart:ui' show Offset;

import '../../../core/assets/asset_paths.dart';
import '../../../core/assets/json_asset_loader.dart';
import '../../../core/domain/character_id.dart';
import '../domain/character_action.dart';
import '../domain/character_pose.dart';
import '../domain/character_repository.dart';

/// Reads `assets/characters/manifest.json` (written by
/// `tools/characters/process_poses.py`).
class CharacterRepositoryImpl implements CharacterRepository {
  const CharacterRepositoryImpl(this._loader);

  final JsonAssetLoader _loader;

  @override
  Future<CharacterRoster> loadRoster() async {
    final json = await _loader.load(AssetPaths.characterManifest);
    final chars = json['characters'] as Map<String, dynamic>;
    final poses = <CharacterId, Map<CharacterAction, CharacterPose>>{};

    for (final id in CharacterId.values) {
      final raw = chars[id.name] as Map<String, dynamic>? ?? const {};
      poses[id] = {
        for (final action in CharacterAction.values)
          if (raw[action.name] case final Map<String, dynamic> p)
            action: CharacterPose(
              character: id,
              action: action,
              asset: '${AssetPaths.characters}/${p['file']}',
              smallAsset: '${AssetPaths.characters}/${p['small']}',
              width: (p['width'] as num).toDouble(),
              height: (p['height'] as num).toDouble(),
              headCenter: Offset(
                ((p['head_center'] as List)[0] as num).toDouble(),
                ((p['head_center'] as List)[1] as num).toDouble(),
              ),
            ),
      };
    }
    return CharacterRoster(poses);
  }
}

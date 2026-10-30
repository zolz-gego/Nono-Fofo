import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/match_letters_config.dart';

/// Loads `assets/content/games/match_letters.json` (once).
class MatchLettersConfigRepository {
  MatchLettersConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  MatchLettersConfig? _config;

  Future<MatchLettersConfig> load() async =>
      _config ??= MatchLettersConfig.fromJson(
        await _loader.load(AssetPaths.gameConfig('match_letters')),
      );
}

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/where_letter_config.dart';

/// Loads `assets/content/games/where_letter.json` (once).
class WhereLetterConfigRepository {
  WhereLetterConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  WhereLetterConfig? _config;

  Future<WhereLetterConfig> load() async =>
      _config ??= WhereLetterConfig.fromJson(
        await _loader.load(AssetPaths.gameConfig('where_letter')),
      );
}

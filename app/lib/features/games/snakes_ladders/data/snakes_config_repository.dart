import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/snakes_config.dart';

/// Loads `assets/content/games/snakes_ladders.json` (once).
class SnakesConfigRepository {
  SnakesConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  SnakesConfig? _config;

  Future<SnakesConfig> load() async => _config ??= SnakesConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('snakes_ladders')),
  );
}

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/adventure_config.dart';

/// Loads `assets/content/games/adventure.json` (once).
class AdventureConfigRepository {
  AdventureConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  AdventureConfig? _config;

  Future<AdventureConfig> load() async => _config ??= AdventureConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('adventure')),
  );
}

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/fishing_config.dart';

/// Loads `assets/content/games/fishing.json` (once).
class FishingConfigRepository {
  FishingConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  FishingConfig? _cache;

  Future<FishingConfig> load() async => _cache ??= FishingConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('fishing')),
  );
}

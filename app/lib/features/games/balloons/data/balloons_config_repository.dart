import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/balloons_config.dart';

/// Loads `assets/content/games/balloons.json` (once).
class BalloonsConfigRepository {
  BalloonsConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  BalloonsConfig? _cache;

  Future<BalloonsConfig> load() async => _cache ??= BalloonsConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('balloons')),
  );
}

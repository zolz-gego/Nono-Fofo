import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/monastery_config.dart';

/// Loads `assets/content/games/monastery.json` (once).
class MonasteryConfigRepository {
  MonasteryConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  MonasteryConfig? _config;

  Future<MonasteryConfig> load() async => _config ??= MonasteryConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('monastery')),
  );
}

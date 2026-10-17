import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/cards_config.dart';

/// Loads `assets/content/games/cards.json` (once).
class CardsConfigRepository {
  CardsConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  CardsConfig? _config;

  Future<CardsConfig> load() async => _config ??= CardsConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('cards')),
  );
}

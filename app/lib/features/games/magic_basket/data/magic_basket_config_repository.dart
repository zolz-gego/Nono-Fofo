import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/magic_basket_config.dart';

/// Loads `assets/content/games/magic_basket.json` (once).
class MagicBasketConfigRepository {
  MagicBasketConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  MagicBasketConfig? _cache;

  Future<MagicBasketConfig> load() async =>
      _cache ??= MagicBasketConfig.fromJson(
        await _loader.load(AssetPaths.gameConfig('magic_basket')),
      );
}

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/letter_strokes.dart';
import '../domain/writing_config.dart';

/// Loads `assets/content/games/writing.json` and the stroke order in
/// `writing_strokes.json` (once each).
class WritingConfigRepository {
  WritingConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  WritingConfig? _config;
  StrokeBook? _strokes;

  Future<WritingConfig> load() async => _config ??= WritingConfig.fromJson(
    await _loader.load(AssetPaths.gameConfig('writing')),
  );

  Future<StrokeBook> strokes() async => _strokes ??= StrokeBook.fromJson(
    await _loader.load(AssetPaths.gameConfig('writing_strokes')),
  );
}

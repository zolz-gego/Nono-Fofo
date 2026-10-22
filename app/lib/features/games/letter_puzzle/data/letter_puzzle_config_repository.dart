import '../../../../core/assets/asset_paths.dart';
import '../../../../core/assets/json_asset_loader.dart';
import '../domain/letter_puzzle_config.dart';

/// Loads `assets/content/games/letter_puzzle.json` (once).
class LetterPuzzleConfigRepository {
  LetterPuzzleConfigRepository(this._loader);

  final JsonAssetLoader _loader;
  LetterPuzzleConfig? _config;

  Future<LetterPuzzleConfig> load() async =>
      _config ??= LetterPuzzleConfig.fromJson(
        await _loader.load(AssetPaths.gameConfig('letter_puzzle')),
      );
}

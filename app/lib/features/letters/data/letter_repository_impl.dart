import '../../../core/assets/asset_paths.dart';
import '../../../core/assets/json_asset_loader.dart';
import '../../../core/error/failure.dart';
import '../../levels/domain/game_level.dart';
import '../domain/coptic_letter.dart';
import '../domain/letter_repository.dart';

/// Reads `assets/content/letters.json`.
class LetterRepositoryImpl implements LetterRepository {
  LetterRepositoryImpl(this._loader);

  final JsonAssetLoader _loader;
  Map<String, dynamic>? _json;
  Map<String, CopticLetter>? _letters;

  @override
  Future<List<CopticLetter>> lettersOf(GameLevel level) async {
    final json = _json ??= await _loader.load(AssetPaths.letters);
    final letters = _letters ??= {
      for (final raw in json['letters'] as List)
        (raw as Map<String, dynamic>)['id'] as String: _parse(raw),
    };
    final ids = (json['levels'] as Map<String, dynamic>)['${level.number}'];
    if (ids == null) return const [];
    return [
      for (final id in ids as List)
        letters[id] ??
            (throw Failure(
              'letters.json: level ${level.number} uses '
              'unknown letter "$id"',
            )),
    ];
  }

  CopticLetter _parse(Map<String, dynamic> raw) => CopticLetter(
    id: raw['id'] as String,
    small: raw['small'] as String,
    capital: raw['capital'] as String,
    names: (raw['name'] as Map<String, dynamic>).cast<String, String>(),
  );
}

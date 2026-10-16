import '../../levels/domain/game_level.dart';
import 'coptic_letter.dart';

abstract interface class LetterRepository {
  /// The letters a level uses, in the order listed in letters.json.
  Future<List<CopticLetter>> lettersOf(GameLevel level);

  /// The whole alphabet, in the order listed in letters.json.
  Future<List<CopticLetter>> allLetters();
}

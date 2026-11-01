import 'game_level.dart';

/// One game on a level's road. `name` is also the image file name in
/// `assets/games/` (see design/game-prompts.md).
enum LevelGame {
  fishing,
  writeLetter,
  balloons,
  cards,
  monastery,
  challenge,
  magicBasket,
  matchLetters,
  letterPuzzle,
  whereLetter,
  soundCards;

  /// Games on each level's road, in order.
  static List<LevelGame> of(GameLevel level) => switch (level) {
    GameLevel.one => const [
      fishing,
      writeLetter,
      balloons,
      cards,
      monastery,
      challenge,
    ],
    GameLevel.two => const [
      magicBasket,
      matchLetters,
      letterPuzzle,
      whereLetter,
      soundCards,
    ],
    GameLevel.three => const [],
  };
}

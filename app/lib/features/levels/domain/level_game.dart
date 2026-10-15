import 'game_level.dart';

/// One game on a level's road. `name` is also the image file name in
/// `assets/games/` (see design/game-prompts.md).
enum LevelGame {
  fishing,
  writeLetter,
  balloons,
  challenge;

  /// Games on each level's road, in order.
  static List<LevelGame> of(GameLevel level) => switch (level) {
    GameLevel.one => const [fishing, writeLetter, balloons, challenge],
    GameLevel.two || GameLevel.three => const [],
  };
}

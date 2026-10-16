/// The settings every "find the letter" game shares (fishing, balloons…):
/// how many to collect, how many letters mix in, and the star limits. Each
/// game's config adds its own art and speeds on top.
abstract interface class LetterHuntRules {
  /// Correct letters needed to finish.
  int get catchesToWin;

  /// How many different letters appear in one game (the target included).
  int get maxDifferentLetters;

  /// 0..1, how often a new item carries the target letter.
  double get targetChance;

  /// Whether a target that gets away counts as a mistake.
  bool get countMissedAsMistake;

  int starsFor(int mistakes);
}

/// Stars from mistakes: up to [threeStarsMax] = 3, up to [twoStarsMax] = 2,
/// more = 1 (a finished game never gets less).
int starsForMistakes(
  int mistakes, {
  required int threeStarsMax,
  required int twoStarsMax,
}) {
  if (mistakes <= threeStarsMax) return 3;
  if (mistakes <= twoStarsMax) return 2;
  return 1;
}

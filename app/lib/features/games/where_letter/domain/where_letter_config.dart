/// Settings from `assets/content/games/where_letter.json`. The words come
/// from the Letter puzzle's list. Defaults here are only used for keys
/// missing from the file.
class WhereLetterConfig {
  const WhereLetterConfig({
    this.wordsPerRound = 10,
    this.options = 3,
    this.threeStarsMaxMistakes = 2,
    this.twoStarsMaxMistakes = 5,
    this.wordDoneFor = const Duration(milliseconds: 1700),
  });

  factory WhereLetterConfig.fromJson(Map<String, dynamic> json) {
    const d = WhereLetterConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final wordDone = json['wordDoneMs'] as num?;
    return WhereLetterConfig(
      wordsPerRound:
          (json['wordsPerRound'] as num?)?.toInt() ?? d.wordsPerRound,
      options: (json['options'] as num?)?.toInt() ?? d.options,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      wordDoneFor: wordDone == null
          ? d.wordDoneFor
          : Duration(milliseconds: wordDone.toInt()),
    );
  }

  final int wordsPerRound;

  /// Options per choice (the right one included).
  final int options;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;

  /// How long a finished word (and its Arabic/English word) stays before
  /// the next one.
  final Duration wordDoneFor;

  /// Stars for a round with [mistakes] (wrong picks + hints).
  int starsFor(int mistakes) => mistakes <= threeStarsMaxMistakes
      ? 3
      : mistakes <= twoStarsMaxMistakes
      ? 2
      : 1;
}

/// Settings from `assets/content/games/match_letters.json`. The words come
/// from the Letter puzzle's list. Defaults here are only used for keys
/// missing from the file.
class MatchLettersConfig {
  const MatchLettersConfig({
    this.wordsPerRound = 10,
    this.threeStarsMaxMistakes = 2,
    this.twoStarsMaxMistakes = 5,
    this.checkDelay = const Duration(milliseconds: 500),
    this.redFor = const Duration(milliseconds: 1300),
    this.wordDoneFor = const Duration(milliseconds: 1700),
  });

  factory MatchLettersConfig.fromJson(Map<String, dynamic> json) {
    const d = MatchLettersConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    Duration ms(String key, Duration fallback) {
      final v = json[key] as num?;
      return v == null ? fallback : Duration(milliseconds: v.toInt());
    }

    return MatchLettersConfig(
      wordsPerRound:
          (json['wordsPerRound'] as num?)?.toInt() ?? d.wordsPerRound,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      checkDelay: ms('checkDelayMs', d.checkDelay),
      redFor: ms('redMs', d.redFor),
      wordDoneFor: ms('wordDoneMs', d.wordDoneFor),
    );
  }

  final int wordsPerRound;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;

  /// Pause after the last line before the check.
  final Duration checkDelay;

  /// How long red lines show before they go.
  final Duration redFor;

  /// How long a finished word stays before the next one.
  final Duration wordDoneFor;

  /// Stars for a round with [mistakes] (red lines + hints).
  int starsFor(int mistakes) => mistakes <= threeStarsMaxMistakes
      ? 3
      : mistakes <= twoStarsMaxMistakes
      ? 2
      : 1;
}

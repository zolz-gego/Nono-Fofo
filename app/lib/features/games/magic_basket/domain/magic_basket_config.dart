import '../../letter_hunt/domain/letter_hunt_rules.dart';

/// Settings from `assets/content/games/magic_basket.json`. Defaults here
/// are only used for keys missing from the file.
class MagicBasketConfig {
  const MagicBasketConfig({
    this.catchesToWin = 5,
    this.targetChance = 0.4,
    this.maxApplesOnScreen = 4,
    this.dropEverySeconds = 1.6,
    this.fallSeconds = 4.5,
    this.countMissedAsMistake = true,
    this.threeStarsMaxMistakes = 0,
    this.twoStarsMaxMistakes = 2,
    this.background,
    this.feetY = 0.9,
  });

  factory MagicBasketConfig.fromJson(Map<String, dynamic> json) {
    const d = MagicBasketConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final marks = json['backgroundMarks'] as Map<String, dynamic>? ?? const {};
    return MagicBasketConfig(
      catchesToWin: (json['catchesToWin'] as num?)?.toInt() ?? d.catchesToWin,
      targetChance:
          (json['targetChance'] as num?)?.toDouble() ?? d.targetChance,
      maxApplesOnScreen:
          (json['maxApplesOnScreen'] as num?)?.toInt() ?? d.maxApplesOnScreen,
      dropEverySeconds:
          (json['dropEverySeconds'] as num?)?.toDouble() ?? d.dropEverySeconds,
      fallSeconds: (json['fallSeconds'] as num?)?.toDouble() ?? d.fallSeconds,
      countMissedAsMistake:
          json['countMissedAsMistake'] as bool? ?? d.countMissedAsMistake,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      background: json['background'] as String?,
      feetY: (marks['feetY'] as num?)?.toDouble() ?? d.feetY,
    );
  }

  /// Correct apples needed to finish (more if the letter has more sounds).
  final int catchesToWin;

  /// 0..1, how often a new apple carries one of the letter's sounds.
  final double targetChance;
  final int maxApplesOnScreen;
  final double dropEverySeconds;

  /// Seconds an apple takes from the tree to the ground.
  final double fallSeconds;

  /// Whether a right apple hitting the ground counts as a mistake.
  final bool countMissedAsMistake;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;
  final String? background;

  /// Where the brothers' feet go in the background picture (fraction of
  /// its height).
  final double feetY;

  int starsFor(int mistakes) => starsForMistakes(
    mistakes,
    threeStarsMax: threeStarsMaxMistakes,
    twoStarsMax: twoStarsMaxMistakes,
  );
}

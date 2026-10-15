/// Which way the fish swim.
enum SwimDirection { ltr, rtl, both }

/// Settings from `assets/content/games/fishing.json`. Defaults here are only
/// used for keys missing from the file.
class FishingConfig {
  const FishingConfig({
    this.catchesToWin = 5,
    this.maxDifferentLetters = 7,
    this.targetChance = 0.35,
    this.maxFishOnScreen = 6,
    this.spawnEverySeconds = 1.4,
    this.swimSeconds = 9,
    this.swimDirection = SwimDirection.ltr,
    this.countMissedAsMistake = true,
    this.threeStarsMaxMistakes = 0,
    this.twoStarsMaxMistakes = 2,
    this.fishImages = const [],
    this.background,
  });

  factory FishingConfig.fromJson(Map<String, dynamic> json) {
    const d = FishingConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    return FishingConfig(
      catchesToWin: (json['catchesToWin'] as num?)?.toInt() ?? d.catchesToWin,
      maxDifferentLetters:
          (json['maxDifferentLetters'] as num?)?.toInt() ??
          d.maxDifferentLetters,
      targetChance:
          (json['targetChance'] as num?)?.toDouble() ?? d.targetChance,
      maxFishOnScreen:
          (json['maxFishOnScreen'] as num?)?.toInt() ?? d.maxFishOnScreen,
      spawnEverySeconds:
          (json['spawnEverySeconds'] as num?)?.toDouble() ??
          d.spawnEverySeconds,
      swimSeconds: (json['swimSeconds'] as num?)?.toDouble() ?? d.swimSeconds,
      swimDirection:
          SwimDirection.values.asNameMap()[json['swimDirection']] ??
          d.swimDirection,
      countMissedAsMistake:
          json['countMissedAsMistake'] as bool? ?? d.countMissedAsMistake,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      fishImages: (json['fishImages'] as List?)?.cast<String>() ?? d.fishImages,
      background: json['background'] as String?,
    );
  }

  final int catchesToWin;
  final int maxDifferentLetters;
  final double targetChance;
  final int maxFishOnScreen;
  final double spawnEverySeconds;
  final double swimSeconds;
  final SwimDirection swimDirection;
  final bool countMissedAsMistake;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;
  final List<String> fishImages;
  final String? background;

  int starsFor(int mistakes) {
    if (mistakes <= threeStarsMaxMistakes) return 3;
    if (mistakes <= twoStarsMaxMistakes) return 2;
    return 1;
  }
}

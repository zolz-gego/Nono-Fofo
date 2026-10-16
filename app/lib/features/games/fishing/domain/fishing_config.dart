import 'dart:ui' show Offset;

import '../../letter_hunt/domain/letter_hunt_rules.dart';

/// Where the letter goes on a painted fish image, as fractions of the image:
/// center ([center].dx of the width, [center].dy of the height) and the
/// letter size (of the height).
class LetterSpot {
  const LetterSpot(this.center, this.size);

  static const LetterSpot fallback = LetterSpot(Offset(0.5, 0.5), 0.45);

  final Offset center;
  final double size;
}

/// Where things are in the Nile background picture: y values are fractions
/// of its height, x values of its width.
class BackgroundMarks {
  const BackgroundMarks({
    this.waterTop = 0.42,
    this.bankTop = 0.327,
    this.leftBankX = 0.08,
    this.rightBankX = 0.92,
    this.leftBankEdge = 0.165,
    this.bedTop = 0.87,
  });

  factory BackgroundMarks.fromJson(Map<String, dynamic> json) {
    const d = BackgroundMarks();
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return BackgroundMarks(
      waterTop: read('waterTop', d.waterTop),
      bankTop: read('bankTop', d.bankTop),
      leftBankX: read('leftBankX', d.leftBankX),
      rightBankX: read('rightBankX', d.rightBankX),
      leftBankEdge: read('leftBankEdge', d.leftBankEdge),
      bedTop: read('bedTop', d.bedTop),
    );
  }

  final double waterTop;
  final double bankTop;
  final double leftBankX;
  final double rightBankX;
  final double leftBankEdge;
  final double bedTop;
}

/// Which way the fish swim.
enum SwimDirection { ltr, rtl, both }

/// Settings from `assets/content/games/fishing.json`. Defaults here are only
/// used for keys missing from the file.
class FishingConfig implements LetterHuntRules {
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
    this.fishLetterSpot = LetterSpot.fallback,
    this.background,
    this.backgroundMarks = const BackgroundMarks(),
  });

  factory FishingConfig.fromJson(Map<String, dynamic> json) {
    const d = FishingConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final spot = json['fishLetterSpot'] as Map<String, dynamic>?;
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
      fishLetterSpot: spot == null
          ? d.fishLetterSpot
          : LetterSpot(
              Offset(
                (spot['x'] as num).toDouble(),
                (spot['y'] as num).toDouble(),
              ),
              (spot['size'] as num).toDouble(),
            ),
      background: json['background'] as String?,
      backgroundMarks: BackgroundMarks.fromJson(
        json['backgroundMarks'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  final int catchesToWin;
  @override
  final int maxDifferentLetters;
  @override
  final double targetChance;
  final int maxFishOnScreen;
  final double spawnEverySeconds;
  final double swimSeconds;
  final SwimDirection swimDirection;
  @override
  final bool countMissedAsMistake;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;
  final List<String> fishImages;
  final LetterSpot fishLetterSpot;
  final String? background;
  final BackgroundMarks backgroundMarks;

  @override
  int starsFor(int mistakes) => starsForMistakes(
    mistakes,
    threeStarsMax: threeStarsMaxMistakes,
    twoStarsMax: twoStarsMaxMistakes,
  );
}

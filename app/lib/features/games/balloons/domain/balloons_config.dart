import 'dart:ui' show Offset;

import '../../letter_hunt/domain/letter_hunt_rules.dart';

/// Where the letter goes on a painted balloon image, as fractions of the
/// image: center ([center].dx of the width, [center].dy of the height) and
/// the letter size (of the width).
class BalloonLetterSpot {
  const BalloonLetterSpot(this.center, this.size);

  static const BalloonLetterSpot fallback = BalloonLetterSpot(
    Offset(0.5, 0.4),
    0.42,
  );

  final Offset center;
  final double size;
}

/// Settings from `assets/content/games/balloons.json`. Defaults here are
/// only used for keys missing from the file.
class BalloonsConfig implements LetterHuntRules {
  const BalloonsConfig({
    this.catchesToWin = 5,
    this.maxDifferentLetters = 7,
    this.targetChance = 0.35,
    this.maxBalloonsOnScreen = 7,
    this.spawnEverySeconds = 1.2,
    this.riseSeconds = 11,
    this.countMissedAsMistake = true,
    this.threeStarsMaxMistakes = 0,
    this.twoStarsMaxMistakes = 2,
    this.balloonImages = const [],
    this.balloonLetterSpot = BalloonLetterSpot.fallback,
    this.background,
    this.feetY = 0.9,
  });

  factory BalloonsConfig.fromJson(Map<String, dynamic> json) {
    const d = BalloonsConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final spot = json['balloonLetterSpot'] as Map<String, dynamic>?;
    final marks = json['backgroundMarks'] as Map<String, dynamic>? ?? const {};
    return BalloonsConfig(
      catchesToWin: (json['catchesToWin'] as num?)?.toInt() ?? d.catchesToWin,
      maxDifferentLetters:
          (json['maxDifferentLetters'] as num?)?.toInt() ??
          d.maxDifferentLetters,
      targetChance:
          (json['targetChance'] as num?)?.toDouble() ?? d.targetChance,
      maxBalloonsOnScreen:
          (json['maxBalloonsOnScreen'] as num?)?.toInt() ??
          d.maxBalloonsOnScreen,
      spawnEverySeconds:
          (json['spawnEverySeconds'] as num?)?.toDouble() ??
          d.spawnEverySeconds,
      riseSeconds: (json['riseSeconds'] as num?)?.toDouble() ?? d.riseSeconds,
      countMissedAsMistake:
          json['countMissedAsMistake'] as bool? ?? d.countMissedAsMistake,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      balloonImages:
          (json['balloonImages'] as List?)?.cast<String>() ?? d.balloonImages,
      balloonLetterSpot: spot == null
          ? d.balloonLetterSpot
          : BalloonLetterSpot(
              Offset(
                (spot['x'] as num).toDouble(),
                (spot['y'] as num).toDouble(),
              ),
              (spot['size'] as num).toDouble(),
            ),
      background: json['background'] as String?,
      feetY: (marks['feetY'] as num?)?.toDouble() ?? d.feetY,
    );
  }

  @override
  final int catchesToWin;
  @override
  final int maxDifferentLetters;
  @override
  final double targetChance;
  final int maxBalloonsOnScreen;
  final double spawnEverySeconds;

  /// Seconds a balloon takes from the bottom of the screen to the top.
  final double riseSeconds;
  @override
  final bool countMissedAsMistake;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;
  final List<String> balloonImages;
  final BalloonLetterSpot balloonLetterSpot;
  final String? background;

  /// Where the brothers' feet go in the background picture (fraction of
  /// its height).
  final double feetY;

  @override
  int starsFor(int mistakes) => starsForMistakes(
    mistakes,
    threeStarsMax: threeStarsMaxMistakes,
    twoStarsMax: twoStarsMaxMistakes,
  );
}

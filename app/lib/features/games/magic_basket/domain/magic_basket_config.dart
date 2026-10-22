import 'dart:ui' show Offset;

import '../../balloons/domain/balloons_config.dart';
import '../../letter_hunt/domain/letter_hunt_rules.dart';

/// Spots on the tree picture, as fractions of it (drawn as in English;
/// Arabic mirrors it).
class TreeMarks {
  const TreeMarks({
    this.seat = const Offset(0.33, 0.6),
    this.rootY = 0.95,
    this.dropY = 0.5,
  });

  factory TreeMarks.fromJson(Map<String, dynamic>? json) {
    const d = TreeMarks();
    if (json == null) return d;
    return TreeMarks(
      seat: Offset(
        (json['seatX'] as num?)?.toDouble() ?? d.seat.dx,
        (json['seatY'] as num?)?.toDouble() ?? d.seat.dy,
      ),
      rootY: (json['rootY'] as num?)?.toDouble() ?? d.rootY,
      dropY: (json['dropY'] as num?)?.toDouble() ?? d.dropY,
    );
  }

  /// Where the brother sits on the branch.
  final Offset seat;

  /// The line of the roots, which stands on the path.
  final double rootY;

  /// Where apples come out of the leaves.
  final double dropY;
}

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
    this.treeImage,
    this.treeMarks = const TreeMarks(),
    this.appleImage,
    this.appleLetterSpot = const BalloonLetterSpot(Offset(0.5, 0.59), 0.58),
    this.basketImage,
    this.basketOpening = 0.27,
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
      treeImage: json['treeImage'] as String?,
      treeMarks: TreeMarks.fromJson(json['treeMarks'] as Map<String, dynamic>?),
      appleImage: json['appleImage'] as String?,
      appleLetterSpot: switch (json['appleLetterSpot']) {
        {'x': final num x, 'y': final num y, 'size': final num size} =>
          BalloonLetterSpot(
            Offset(x.toDouble(), y.toDouble()),
            size.toDouble(),
          ),
        _ => d.appleLetterSpot,
      },
      basketImage: json['basketImage'] as String?,
      basketOpening:
          (json['basketOpening'] as num?)?.toDouble() ?? d.basketOpening,
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

  /// Pictures (drawn in code while null or missing).
  final String? treeImage;
  final TreeMarks treeMarks;
  final String? appleImage;

  /// Where the sound goes on the apple picture.
  final BalloonLetterSpot appleLetterSpot;
  final String? basketImage;

  /// The line across the middle of the basket's opening (fraction of the
  /// basket picture's height).
  final double basketOpening;

  int starsFor(int mistakes) => starsForMistakes(
    mistakes,
    threeStarsMax: threeStarsMaxMistakes,
    twoStarsMax: twoStarsMaxMistakes,
  );
}

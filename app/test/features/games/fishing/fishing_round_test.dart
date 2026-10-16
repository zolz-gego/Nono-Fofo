import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/fishing/domain/fishing_config.dart';
import 'package:nonofofo/features/games/fishing/domain/fishing_round.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

CopticLetter _letter(String key) =>
    CopticLetter(id: key, small: key, capital: key.toUpperCase(), names: {'en': key});

void main() {
  final pool = [for (final k in 'abcdefghijkl'.split('')) _letter(k)];
  final target = pool.first;
  const config = FishingConfig(catchesToWin: 3, maxDifferentLetters: 4);

  FishingRound start() =>
      FishingRound.start(config: config, target: target, pool: pool, random: Random(1));

  test('uses the target plus at most maxDifferentLetters - 1 others', () {
    final round = start();
    expect(round.letters.first, target);
    expect(round.letters.length, 4);
    expect(round.letters.toSet().length, 4);
  });

  test('every fish letter comes from the round letters', () {
    final round = start();
    final random = Random(2);
    for (var i = 0; i < 200; i++) {
      expect(round.letters,
          contains(round.nextFishLetter(random, targetsSwimming: i % 2)));
    }
  });

  test('a perfect game gets 3 stars and finishes at the goal', () {
    var round = start();
    for (var i = 0; i < 3; i++) {
      round = round.catchFish(target);
    }
    expect(round.isFinished, isTrue);
    expect(round.stars, 3);
    expect(round.catchFish(target).caught, 3);
  });

  test('wrong catches and missed targets cost stars', () {
    var round = start().catchFish(pool[1]);
    expect(round.stars, 2);
    round = round.missTarget().catchFish(pool[2]);
    expect(round.mistakes, 3);
    expect(round.stars, 1);
  });

  test('missed targets can be ignored by config', () {
    final round = FishingRound.start(
      config: const FishingConfig(countMissedAsMistake: false),
      target: target,
      pool: pool,
    ).missTarget();
    expect(round.stars, 3);
  });
}

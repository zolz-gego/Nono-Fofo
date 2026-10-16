import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/balloons/domain/balloons_config.dart';

void main() {
  test('reads the shipped balloons.json', () {
    final json = jsonDecode(
      File('assets/content/games/balloons.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final config = BalloonsConfig.fromJson(json);
    expect(config.catchesToWin, 5);
    expect(config.maxDifferentLetters, 7);
    expect(config.riseSeconds, greaterThan(0));
    expect(config.feetY, inInclusiveRange(0.5, 1.0));
  });

  test('missing keys fall back to defaults, stars follow the limits', () {
    final config = BalloonsConfig.fromJson(const {
      'stars': {'threeStarsMaxMistakes': 1, 'twoStarsMaxMistakes': 3},
    });
    expect(config.catchesToWin, 5);
    expect(config.balloonImages, isEmpty);
    expect(config.starsFor(1), 3);
    expect(config.starsFor(3), 2);
    expect(config.starsFor(4), 1);
  });
}

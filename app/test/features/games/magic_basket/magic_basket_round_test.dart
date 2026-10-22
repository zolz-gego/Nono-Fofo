import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/magic_basket/domain/magic_basket_config.dart';
import 'package:nonofofo/features/games/magic_basket/domain/magic_basket_round.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

CopticLetter _letter(
  String id,
  List<String> sounds, [
  List<String> neverDrop = const [],
]) => CopticLetter(
  id: id,
  small: id,
  capital: id.toUpperCase(),
  names: {'ar': id},
  sounds: {'ar': sounds},
  neverDrop: {'ar': neverDrop},
);

void main() {
  final vida = _letter('vida', ['ب', 'ڤ'], ['ف']);
  final tav = _letter('tav', ['ت'], ['د', 'تي']);
  final pool = [
    vida,
    tav,
    _letter('delta', ['د', 'ذ']),
    _letter('phi', ['ف']),
    _letter('pi', ['ب']),
    _letter('ti', ['تي']),
    _letter('mi', ['م']),
  ];
  const config = MagicBasketConfig(catchesToWin: 5);

  MagicBasketRound start(CopticLetter target) => MagicBasketRound.start(
    config: config,
    target: target,
    pool: pool,
    language: 'ar',
  );

  test('wrong apples never carry the letter\'s own or debatable sounds', () {
    final round = start(tav);
    expect(round.distractors, isNot(contains('ت')));
    expect(round.distractors, isNot(contains('د')));
    expect(round.distractors, isNot(contains('تي')));
    expect(round.distractors, containsAll(['ذ', 'م', 'ب']));
  });

  test('a shared sound counts as right and never falls as wrong', () {
    final round = start(vida);
    expect(round.distractors, isNot(contains('ب')));
    expect(round.distractors, isNot(contains('ف')));
    expect(round.judge('ب'), BasketCatch.correct);
  });

  test('needs every sound: the last slots only take missing sounds', () {
    var round = start(vida);
    for (var i = 0; i < 4; i++) {
      round = round.pick('ب');
    }
    expect(round.caught.length, 4);
    expect(round.onlyMissingFit, isTrue);
    expect(round.judge('ب'), BasketCatch.notNeeded);
    expect(round.pick('ب').caught.length, 4);
    round = round.pick('ڤ');
    expect(round.isFinished, isTrue);
  });

  test('once only missing sounds fit, right apples carry them', () {
    var round = start(vida);
    for (var i = 0; i < 4; i++) {
      round = round.pick('ب');
    }
    final random = Random(3);
    for (var i = 0; i < 50; i++) {
      final s = round.nextSound(random, rightShowing: 0, right: true);
      expect(s, 'ڤ');
    }
  });

  test('wrong catches and fallen needed apples are mistakes', () {
    var round = start(tav);
    round = round.pick('م').miss();
    expect(round.mistakes, 2);
    expect(round.stars, 2);
  });

  test('every letter but so has Arabic and English sounds', () {
    final json =
        jsonDecode(File('assets/content/letters.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final raw in json['letters'] as List) {
      final l = raw as Map<String, dynamic>;
      if (l['id'] == 'so') continue;
      final sounds = l['sounds'] as Map<String, dynamic>?;
      expect(sounds?['ar'], isNotEmpty, reason: l['id'] as String);
      expect(sounds?['en'], isNotEmpty, reason: l['id'] as String);
    }
    expect((json['levels'] as Map)['2'], isNot(contains('so')));
  });
}

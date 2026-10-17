import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/monastery/domain/hidden_letter.dart';
import 'package:nonofofo/features/games/monastery/domain/monastery_config.dart';
import 'package:nonofofo/features/games/monastery/presentation/monastery_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/games/progress/domain/timed_record.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Progress extends Mock implements GameProgressRepository {}

CopticLetter _letter(String id) => CopticLetter(
  id: id,
  small: id,
  capital: id.toUpperCase(),
  names: {'en': id},
);

final _alphabet = [
  for (final id in 'abcdefghijklmnopqrstuvwxyz123456'.split('')) _letter(id),
];

MonasteryConfig _realConfig() => MonasteryConfig.fromJson(
  jsonDecode(File('assets/content/games/monastery.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  setUpAll(
    () =>
        registerFallbackValue(const TimedRecord(time: Duration.zero, moves: 0)),
  );

  group('config', () {
    test('the real file has room for the biggest level', () {
      final config = _realConfig();
      final most = config.letterCounts.reduce(max);
      for (var seed = 0; seed < 50; seed++) {
        final letters = hideLetters(
          alphabet: _alphabet,
          config: config,
          count: most,
          random: Random(seed),
        );
        expect(letters, hasLength(most), reason: 'seed $seed');
      }
      expect(config.scene.objects, isNotEmpty);
      for (final s in config.scene.spots) {
        expect(s.x, inInclusiveRange(0, 1));
        expect(s.y, inInclusiveRange(0, 1));
      }
    });
  });

  group('hideLetters', () {
    final config = _realConfig();

    test('different letters, spots kept apart', () {
      final letters = hideLetters(
        alphabet: _alphabet,
        config: config,
        count: 10,
        random: Random(4),
      );
      expect(letters.map((l) => l.letter).toSet(), hasLength(10));
      for (var i = 0; i < letters.length; i++) {
        for (var j = i + 1; j < letters.length; j++) {
          expect(
            sceneDistance(
              letters[i].center,
              letters[j].center,
              config.scene.aspect,
            ),
            greaterThanOrEqualTo(config.minSpotGap),
          );
        }
      }
    });

    test('a new game hides them somewhere else', () {
      Set<Offset> spots(int seed) => {
        for (final l in hideLetters(
          alphabet: _alphabet,
          config: config,
          count: 5,
          random: Random(seed),
        ))
          l.center,
      };
      expect(spots(1), isNot(equals(spots(2))));
    });
  });

  group('MonasteryCubit', () {
    late _Progress progress;
    const spotA = HidingSpot(x: 0.2, y: 0.5, size: 0.1);
    const spotB = HidingSpot(x: 0.8, y: 0.5, size: 0.1);
    final letters = [
      HiddenLetter(
        letter: _alphabet[0],
        capital: true,
        spot: spotA,
        color: const Color(0xFF000000),
      ),
      HiddenLetter(
        letter: _alphabet[1],
        capital: false,
        spot: spotB,
        color: const Color(0xFF000000),
      ),
    ];

    setUp(() {
      progress = _Progress();
      when(() => progress.bestTime(any(), any())).thenReturn(null);
      when(
        () => progress.saveTime(any(), any(), any()),
      ).thenAnswer((_) async => true);
    });

    MonasteryCubit make() =>
        MonasteryCubit(progress, letters: letters, aspect: 16 / 9);

    test('finds the letter under a tap, misses elsewhere', () {
      final cubit = make();
      expect(cubit.letterAt(const Offset(0.21, 0.52)), 0);
      expect(cubit.letterAt(const Offset(0.8, 0.5)), 1);
      expect(cubit.letterAt(const Offset(0.5, 0.5)), isNull);
    });

    test('a found letter can not be found again', () async {
      final cubit = make();
      await cubit.reveal(0);
      expect(cubit.state.event, MonasteryEvent.found);
      expect(cubit.letterAt(const Offset(0.2, 0.5)), isNull);
    });

    test('counts wrong taps and hints, and saves the run', () async {
      final cubit = make()..start();
      cubit
        ..miss()
        ..miss()
        ..hint();
      expect(cubit.state.wrongTaps, 2);
      expect(cubit.state.hints, 1);
      expect(cubit.state.event, MonasteryEvent.hint);
      await cubit.reveal(0);
      await cubit.reveal(1);
      expect(cubit.state.solved, isTrue);
      expect(cubit.state.event, MonasteryEvent.solved);
      expect(cubit.state.newRecord, isTrue);
      final saved =
          verify(
                () => progress.saveTime(MonasteryCubit.id, '2', captureAny()),
              ).captured.single
              as TimedRecord;
      expect(saved.moves, 2);
    });

    test('hints only point at letters not found yet', () async {
      final cubit = make();
      await cubit.reveal(0);
      for (var i = 0; i < 10; i++) {
        cubit.hint();
        expect(cubit.state.last, 1);
      }
    });
  });
}

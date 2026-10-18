import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/adventure/domain/adventure_config.dart';
import 'package:nonofofo/features/games/adventure/domain/adventure_level.dart';
import 'package:nonofofo/features/games/adventure/presentation/adventure_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';
import 'package:nonofofo/features/levels/domain/game_level.dart';
import 'package:nonofofo/features/questions/domain/letter_question.dart';

class _Progress extends Mock implements GameProgressRepository {}

CopticLetter _letter(String id) => CopticLetter(
  id: id,
  small: id,
  capital: id.toUpperCase(),
  names: {'en': id},
);

final _pool = [for (final id in 'abcdefghij'.split('')) _letter(id)];

AdventureConfig _realConfig() => AdventureConfig.fromJson(
  jsonDecode(File('assets/content/games/adventure.json').readAsStringSync())
      as Map<String, dynamic>,
);

const _templates = [
  LetterQuestionTemplate(id: 'name', level: 1, show: LetterSide.letter),
];

AdventureCubit _cubit(_Progress progress, {AdventureConfig? config}) =>
    AdventureCubit(
      progress,
      config: config ?? _realConfig(),
      gameLevel: GameLevel.one,
      templates: _templates,
      pool: _pool,
      wait: (_) async {},
    );

void main() {
  group('levels', () {
    final config = _realConfig();

    test('three levels: the Nile, the desert, Alexandria', () {
      expect(config.levels.map((l) => l.place), [
        AdventurePlace.nile,
        AdventurePlace.desert,
        AdventurePlace.alexandria,
      ]);
    });

    for (final level in _realConfig().levels) {
      test('${level.id}: one letter block per letter, a start and a gate', () {
        expect(level.letterBlocks, hasLength(config.letters));
        expect(level.start.col, lessThan(level.gate.col));
        expect(level.checkpoints, isNotEmpty);
        // The hero starts standing on ground.
        expect(level.tiles[level.start.row + 1][level.start.col], Tile.ground);
        // Room after the gate for Grandpa's book.
        expect(level.width - level.gate.col, greaterThan(6));
      });
    }

    test('a row of the wrong length is refused', () {
      expect(
        () => AdventureLevel.fromJson({
          'id': 'bad',
          'place': 'nile',
          'rows': ['@..E', 'GGG'],
        }),
        throwsFormatException,
      );
    });

    test('stars come from the share of coins', () {
      expect(config.starsFor(10, 100), 1);
      expect(config.starsFor(50, 100), 2);
      expect(config.starsFor(90, 100), 3);
    });
  });

  group('cubit', () {
    late _Progress progress;

    setUp(() {
      progress = _Progress();
      when(() => progress.bestStars(any(), any())).thenReturn(0);
      when(() => progress.hasPassed(any(), any())).thenReturn(false);
      when(() => progress.saveStars(any(), any(), any()))
          .thenAnswer((_) async => true);
      when(() => progress.savePassed(any(), any())).thenAnswer((_) async {});
    });

    test('a level starts with 3 lives, small Fofo and 5 letters', () {
      final cubit = _cubit(progress)..startLevel(0);
      expect(cubit.state.lives, 3);
      expect(cubit.state.big, isFalse);
      expect(cubit.state.letters, hasLength(5));
      expect(cubit.state.missing, 5);
    });

    test('every 30 coins gives a life, up to 5', () {
      final cubit = _cubit(progress)..startLevel(0);
      for (var i = 0; i < 29; i++) {
        cubit.addCoins();
      }
      expect(cubit.state.lives, 3);
      cubit.addCoins();
      expect(cubit.state.lives, 4);
      expect(cubit.state.event, AdventureEvent.lifeUp);
      for (var i = 0; i < 90; i++) {
        cubit.addCoins();
      }
      expect(cubit.state.lives, 5);
      expect(cubit.state.coins, 120);
    });

    test('a right letter answer wins the letter', () async {
      final cubit = _cubit(progress)..startLevel(0);
      final asked = cubit.ask(AskKind.letter, letterIndex: 2);
      final q = cubit.state.question!;
      expect(q.answer, cubit.state.letters[2]);
      await cubit.answer(q.answerIndex);
      expect(await asked, isTrue);
      expect(cubit.state.found, {2});
      expect(cubit.state.phase, AdventurePhase.playing);
    });

    test('a wrong letter answer costs a life and keeps the letter', () async {
      final cubit = _cubit(progress)..startLevel(0);
      final asked = cubit.ask(AskKind.letter, letterIndex: 0);
      final q = cubit.state.question!;
      await cubit.answer((q.answerIndex + 1) % q.choices.length);
      expect(await asked, isFalse);
      expect(cubit.state.lives, 2);
      expect(cubit.state.found, isEmpty);
    });

    test(
      'Grandpa\'s page: right grows into Nono, wrong costs nothing',
      () async {
        final cubit = _cubit(progress)..startLevel(0);
        var asked = cubit.ask(AskKind.page);
        var q = cubit.state.question!;
        await cubit.answer((q.answerIndex + 1) % q.choices.length);
        expect(await asked, isFalse);
        expect(cubit.state.big, isFalse);
        expect(cubit.state.lives, 3);

        asked = cubit.ask(AskKind.page);
        q = cubit.state.question!;
        await cubit.answer(q.answerIndex);
        expect(await asked, isTrue);
        expect(cubit.state.big, isTrue);

        cubit.shrink();
        expect(cubit.state.big, isFalse);
        expect(cubit.state.lives, 3);
      },
    );

    test('losing the last life is game over', () {
      final cubit = _cubit(progress)..startLevel(0);
      for (var i = 0; i < 3; i++) {
        cubit.died();
        cubit.afterDeath();
      }
      expect(cubit.state.phase, AdventurePhase.gameOver);
    });

    test(
      'finishing saves stars; all levels done saves the challenge',
      () async {
        when(() => progress.bestStars(any(), any())).thenReturn(2);
        final cubit = _cubit(progress)..startLevel(2);
        cubit.addCoins(10);
        await cubit.complete(const Duration(seconds: 90), 100);
        expect(cubit.state.phase, AdventurePhase.complete);
        expect(cubit.state.stars, 1);
        expect(cubit.state.allDone, isTrue);
        verify(() => progress.saveStars('adventure', 'level1.alexandria', 1))
            .called(1);
        verify(() => progress.savePassed('adventure', 'level1')).called(1);
      },
    );

    test('the bonus letter adds 2 stars at the finish', () async {
      final cubit = _cubit(progress)..startLevel(0);
      cubit
        ..addCoins(90)
        ..bonusFound();
      await cubit.complete(const Duration(seconds: 60), 100);
      expect(cubit.state.stars, 3);
      expect(cubit.state.bonusStars, 2);
      verify(() => progress.saveStars('adventure', 'level1.nile', 5)).called(1);
    });

    test('a level opens once the one before is finished', () {
      when(() => progress.bestStars('adventure', 'level1.nile')).thenReturn(1);
      final cubit = _cubit(progress);
      expect(cubit.unlocked(0), isTrue);
      expect(cubit.unlocked(1), isTrue);
      expect(cubit.unlocked(2), isFalse);
    });
  });
}

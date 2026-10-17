import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/core/domain/character_id.dart';
import 'package:nonofofo/core/error/failure.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/games/snakes_ladders/domain/snakes_board.dart';
import 'package:nonofofo/features/games/snakes_ladders/domain/snakes_config.dart';
import 'package:nonofofo/features/games/snakes_ladders/presentation/snakes_cubit.dart';
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

final _pool = [for (final id in 'abcdefghijklmn'.split('')) _letter(id)];

SnakesConfig _realConfig() => SnakesConfig.fromJson(
  jsonDecode(
    File('assets/content/games/snakes_ladders.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

List<LetterQuestionTemplate> _realTemplates() {
  final json = jsonDecode(
    File('assets/content/questions/letter_mcq.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final q in json['questions'] as List)
      LetterQuestionTemplate.fromJson(q as Map<String, dynamic>),
  ];
}

/// A Random whose nextInt answers come from [ints] (in turn, modulo max).
class _Scripted implements Random {
  _Scripted(this.ints);
  final List<int> ints;
  int _i = 0;

  @override
  int nextInt(int max) => ints[_i++ % ints.length] % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  group('board', () {
    final board = _realConfig().board;

    test('the agreed fixed board: 64 squares, 5 ladders, 5 snakes', () {
      expect(board.squares, 64);
      expect(board.columns, 8);
      expect(board.ladders, {4: 18, 9: 31, 21: 42, 28: 44, 46: 58});
      expect(board.snakes, {17: 7, 30: 15, 51: 12, 55: 33, 61: 43});
    });

    test('squares wind up row by row from the bottom left', () {
      expect(board.cellOf(1), (0, 0));
      expect(board.cellOf(8), (0, 7));
      expect(board.cellOf(9), (1, 7));
      expect(board.cellOf(16), (1, 0));
      expect(board.cellOf(17), (2, 0));
      expect(board.cellOf(64), (7, 0));
    });

    test('hops square by square, then up a ladder or down a snake', () {
      final up = board.move(1, 3);
      expect(up.steps, [2, 3, 4]);
      expect(up.end, 18);
      expect(up.climbed, isTrue);

      final down = board.move(14, 3);
      expect(down.landed, 17);
      expect(down.end, 7);
      expect(down.slid, isTrue);

      expect(board.move(0, 2).end, 2);
    });

    test('must land exactly on the last square', () {
      expect(board.move(60, 4).end, 64);
      final over = board.move(62, 3);
      expect(over.overshoot, isTrue);
      expect(over.end, 62);
    });

    test('rejects broken boards', () {
      expect(
        () => SnakesBoard(squares: 64, columns: 8, ladders: {5: 3}, snakes: {}),
        throwsA(isA<Failure>()),
      );
      expect(
        () => SnakesBoard(
          squares: 64,
          columns: 8,
          ladders: {5: 20},
          snakes: {30: 5},
        ),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('letter questions', () {
    test('three different choices from the pool, the answer among them', () {
      final templates = _realTemplates();
      expect(templates.map((t) => t.show).toSet(), LetterSide.values.toSet());
      for (var seed = 0; seed < 100; seed++) {
        final q = LetterQuestion.make(
          templates: templates,
          pool: _pool,
          random: Random(seed),
        );
        expect(q.choices, hasLength(3));
        expect(q.choices.toSet(), hasLength(3));
        expect(q.choices[q.answerIndex], q.answer);
      }
    });

    test('mixed form shows both capital and small letters', () {
      final forms = {
        for (var seed = 0; seed < 50; seed++)
          LetterQuestion.make(
            templates: _realTemplates(),
            pool: _pool,
            random: Random(seed),
          ).capital,
      };
      expect(forms, {true, false});
    });

    test('skips recently asked letters', () {
      for (var seed = 0; seed < 50; seed++) {
        final q = LetterQuestion.make(
          templates: _realTemplates(),
          pool: _pool,
          random: Random(seed),
          avoid: _pool.skip(1).map((l) => l.id),
        );
        expect(q.answer, _pool.first);
      }
    });
  });

  group('cubit', () {
    late _Progress progress;

    setUp(() {
      progress = _Progress();
      when(() => progress.hasPassed(any(), any())).thenReturn(false);
      when(() => progress.savePassed(any(), any())).thenAnswer((_) async {});
    });

    SnakesCubit cubit({required bool computer, required List<int> ints}) =>
        SnakesCubit(
          progress,
          config: _realConfig(),
          level: GameLevel.one,
          players: [
            const SnakesPlayer(character: CharacterId.nono, name: 'Mina'),
            SnakesPlayer(
              character: CharacterId.fofo,
              name: computer ? 'Fofo' : 'Rafy',
              computer: computer,
            ),
          ],
          templates: _realTemplates(),
          pool: _pool,
          random: _Scripted(ints),
          wait: (_) async {},
        );

    test('the child goes first and gets a question', () {
      final c = cubit(computer: true, ints: [0])..start();
      expect(c.state.current, 0);
      expect(c.state.phase, SnakesPhase.question);
      expect(c.state.question, isNotNull);
    });

    test('a wrong answer passes the turn without moving', () async {
      final c = cubit(computer: false, ints: [0])..start();
      final q = c.state.question!;
      await c.answer((q.answerIndex + 1) % 3);
      expect(c.state.positions, [0, 0]);
      expect(c.state.current, 1);
      expect(c.state.phase, SnakesPhase.question);
      expect(c.state.asked, [1, 0]);
      expect(c.state.correct, [0, 0]);
    });

    test('a right answer rolls and moves, then the other player', () async {
      // nextInt answers: question picks (template, letter, shuffles...) use
      // the same script; the dice reads `ints % 6 + 1`.
      final c = cubit(computer: false, ints: [2])..start();
      await c.answer(c.state.question!.answerIndex);
      expect(c.state.phase, SnakesPhase.roll);
      await c.roll();
      expect(c.state.roll, 3);
      // 0 + 3 = square 3 (no ladder there).
      expect(c.state.positions, [3, 0]);
      expect(c.state.current, 1);
      expect(c.state.correct, [1, 0]);
      expect(c.state.turns, [1, 0]);
    });

    test('the computer rolls without a question', () async {
      final c = cubit(computer: true, ints: [3])..start();
      final q = c.state.question!;
      await c.answer((q.answerIndex + 1) % 3);
      // The computer's roll ran straight away (instant waits).
      await pumpEventQueue();
      // Rolled a 4: square 4 has the ladder up to 18.
      expect(c.state.positions[1], 18);
      expect(c.state.asked, [1, 0]);
      expect(c.state.turns, [0, 1]);
      expect(c.state.current, 0);
    });

    test('beating the computer is saved the first time', () async {
      final c = cubit(computer: true, ints: [3]);
      c.emit(c.state.copyWith(positions: [60, 0]));
      c.start();
      await c.answer(c.state.question!.answerIndex);
      await c.roll();
      expect(c.state.winner, 0);
      expect(c.state.phase, SnakesPhase.done);
      expect(c.state.firstWin, isTrue);
      verify(() => progress.savePassed(SnakesCubit.id, 'level1')).called(1);
    });

    test('a friend game saves nothing', () async {
      final c = cubit(computer: false, ints: [3]);
      c.emit(c.state.copyWith(positions: [60, 0]));
      c.start();
      await c.answer(c.state.question!.answerIndex);
      await c.roll();
      expect(c.state.winner, 0);
      verifyNever(() => progress.savePassed(any(), any()));
    });
  });
}

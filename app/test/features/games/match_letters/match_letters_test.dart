import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/letter_puzzle/domain/letter_puzzle_config.dart';
import 'package:nonofofo/features/games/letter_puzzle/presentation/letter_puzzle_cubit.dart';
import 'package:nonofofo/features/games/match_letters/domain/match_board.dart';
import 'package:nonofofo/features/games/match_letters/domain/match_letters_config.dart';
import 'package:nonofofo/features/games/match_letters/presentation/match_letters_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Progress extends Mock implements GameProgressRepository {}

CopticLetter _l(String id) =>
    CopticLetter(id: id, small: id[0], capital: id[0], names: {'ar': id});

const _word = PuzzleWord(
  text: 'بابا',
  letters: ['pi', 'alpha', 'pi', 'alpha'],
  sounds: ['ب', 'ا', 'ب', 'ا'],
);

void main() {
  final pi = _l('pi'), alpha = _l('alpha');
  final baba = [pi, alpha, pi, alpha];

  /// Links each row to a free sound equal to [want] (row by row).
  MatchBoard draw(MatchBoard b, List<String> want) {
    for (final (row, s) in want.indexed) {
      final sound = [
        for (var i = 0; i < b.sounds.length; i++)
          if (b.sounds[i] == s && b.rowOf(i) == null) i,
      ].first;
      b = b.link(row, sound);
    }
    return b;
  }

  group('MatchBoard', () {
    test('starts with no lines and the word\'s sounds shuffled', () {
      final b = MatchBoard.start(baba, _word.sounds, Random(1));
      expect(b.links, everyElement(isNull));
      expect([...b.sounds]..sort(), [..._word.sounds]..sort());
      expect(b.full, isFalse);
    });

    test('a sound takes one line: linking it again moves the line', () {
      var b = MatchBoard.start(baba, _word.sounds, Random(2));
      b = b.link(0, 0).link(1, 0);
      expect(b.links, [null, 0, null, null]);
    });

    test('repeated letters: either equal sound is right', () {
      final b = draw(MatchBoard.start(baba, _word.sounds, Random(3)), [
        'ب',
        'ا',
        'ب',
        'ا',
      ]);
      expect(b.full, isTrue);
      final checked = b.check();
      expect(checked.solved, isTrue);
      expect(checked.marks, everyElement(LineMark.right));
    });

    test('a wrong check keeps green lines and drops red ones', () {
      var b = draw(MatchBoard.start(baba, _word.sounds, Random(4)), [
        'ب',
        'ب',
        'ا',
        'ا',
      ]).check();
      expect(b.marks, [
        LineMark.right,
        LineMark.wrong,
        LineMark.wrong,
        LineMark.right,
      ]);
      expect(b.wrongCount, 2);
      b = b.clearWrong();
      expect(b.links[1], isNull);
      expect(b.links[2], isNull);
      expect(b.locked, [true, false, false, true]);
      // Green lines and their sounds can't move.
      final locked = b.links[0]!;
      expect(b.link(1, locked), same(b));
    });

    test('a hint draws a right line on the first open row and locks it', () {
      final b = MatchBoard.start(baba, _word.sounds, Random(5)).hint()!;
      expect(b.locked.first, isTrue);
      expect(b.sounds[b.links.first!], 'ب');
      expect(b.marks.first, LineMark.right);
    });
  });

  group('MatchLettersCubit', () {
    test('mistakes are red lines plus hints, stars at the end', () async {
      final progress = _Progress();
      when(() => progress.saveStars(any(), any(), any()))
          .thenAnswer((_) async => true);
      final cubit = MatchLettersCubit(
        progress,
        config: const MatchLettersConfig(),
        length: 4,
        items: [PuzzleItem(word: _word, letters: baba)],
        random: Random(6),
      );
      // Two wrong lines (rows 1 and 2 swapped).
      final drawn = draw(cubit.state.board, ['ب', 'ب', 'ا', 'ا']);
      for (var row = 0; row < 4; row++) {
        cubit.link(row, drawn.links[row]!);
      }
      expect(cubit.state.canPlay, isFalse, reason: 'full: waits for check');
      cubit.check();
      expect(cubit.state.mistakes, 2);
      expect(cubit.state.event, MatchLettersEvent.wrong);
      cubit.clearWrong();
      cubit.hint();
      expect(cubit.state.mistakes, 3);
      while (!cubit.state.board.solved) {
        if (cubit.state.board.full) {
          cubit.check();
        } else {
          cubit.hint();
        }
      }
      await cubit.next();
      expect(cubit.state.finished, isTrue);
      expect(
        cubit.state.stars,
        const MatchLettersConfig().starsFor(cubit.state.mistakes),
      );
      verify(
        () => progress.saveStars(MatchLettersCubit.id, '4', cubit.state.stars),
      ).called(1);
    });
  });

  test('every offered word in letter_puzzle.json has one sound per letter', () {
    final config = LetterPuzzleConfig.fromJson(
      jsonDecode(
        File('assets/content/games/letter_puzzle.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    for (final lang in ['ar', 'en']) {
      for (final w in config.poolFor(lang, LetterPuzzleConfig.mix)) {
        expect(w.sounds.length, w.letters.length, reason: '$lang ${w.text}');
        expect(w.sounds, everyElement(isNotEmpty), reason: w.text);
      }
    }
  });
}

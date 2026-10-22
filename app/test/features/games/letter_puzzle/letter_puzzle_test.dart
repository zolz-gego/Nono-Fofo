import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/letter_puzzle/domain/letter_puzzle_config.dart';
import 'package:nonofofo/features/games/letter_puzzle/domain/puzzle_board.dart';
import 'package:nonofofo/features/games/letter_puzzle/presentation/letter_puzzle_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Progress extends Mock implements GameProgressRepository {}

CopticLetter _l(String id) =>
    CopticLetter(id: id, small: id[0], capital: id[0], names: {'ar': id});

void main() {
  final mi = _l('mi'), ita = _l('ita'), ni = _l('ni'), alpha = _l('alpha');
  final mina = [mi, ita, ni, alpha];

  /// Puts each tile into the cube where [order] says, by letter id.
  PuzzleBoard spell(PuzzleBoard b, List<String> order) {
    final used = <int>{};
    for (final (slot, id) in order.indexed) {
      final t = [
        for (var i = 0; i < b.tiles.length; i++)
          if (b.tiles[i].id == id && !used.contains(i)) i,
      ].first;
      used.add(t);
      b = b.place(t, slot);
    }
    return b;
  }

  group('PuzzleBoard', () {
    test('starts empty with the word\'s own letters, shuffled', () {
      final b = PuzzleBoard.start(mina, Random(1));
      expect(b.slots, everyElement(isNull));
      expect(b.tiles.map((l) => l.id).toList()..sort(), [
        'alpha',
        'ita',
        'mi',
        'ni',
      ]);
      expect(
        b.tiles.map((l) => l.id),
        isNot(orderedEquals(mina.map((l) => l.id))),
      );
    });

    test('a right check locks every cube green', () {
      final b = spell(PuzzleBoard.start(mina, Random(2)), [
        'mi',
        'ita',
        'ni',
        'alpha',
      ]).check();
      expect(b.solved, isTrue);
      expect(b.marks, everyElement(SlotMark.right));
    });

    test('a wrong check keeps green ones and sends red ones back', () {
      var b = spell(PuzzleBoard.start(mina, Random(3)), [
        'mi',
        'ni',
        'ita',
        'alpha',
      ]).check();
      expect(b.marks, [
        SlotMark.right,
        SlotMark.wrong,
        SlotMark.wrong,
        SlotMark.right,
      ]);
      b = b.clearWrong();
      expect(b.slots[0], isNotNull);
      expect(b.slots[1], isNull);
      expect(b.slots[2], isNull);
      expect(b.locked, [true, false, false, true]);
      // Locked cubes don't take another tile.
      final loose = [
        for (var t = 0; t < b.tiles.length; t++)
          if (b.inTray(t)) t,
      ];
      expect(b.place(loose.first, 0), same(b));
    });

    test('dropping on a full cube swaps with where the tile came from', () {
      var b = PuzzleBoard.start(mina, Random(4));
      b = b.place(0, 0).place(1, 1);
      b = b.place(0, 1);
      expect(b.slots[1], 0);
      expect(b.slots[0], 1);
      b = b.place(2, 1); // From the tray: the old tile goes to the tray.
      expect(b.slots[1], 2);
      expect(b.inTray(0), isTrue);
    });

    test('a hint fills the first open cube with its letter', () {
      var b = PuzzleBoard.start(mina, Random(5));
      for (var i = 0; i < 4; i++) {
        b = b.hint()!;
      }
      expect(b.solved, isTrue);
      expect(
        [for (final t in b.slots) b.tiles[t!].id],
        ['mi', 'ita', 'ni', 'alpha'],
      );
      expect(b.hint(), isNull);
    });

    test('repeated letters count right in either cube', () {
      final papa = [_l('pi'), alpha, _l('pi'), alpha];
      final b = spell(PuzzleBoard.start(papa, Random(6)), [
        'pi',
        'alpha',
        'pi',
        'alpha',
      ]).check();
      expect(b.solved, isTrue);
    });
  });

  group('LetterPuzzleCubit', () {
    test('mistakes are failed checks plus hints, stars at the end', () async {
      final progress = _Progress();
      when(() => progress.saveStars(any(), any(), any()))
          .thenAnswer((_) async => true);
      final cubit = LetterPuzzleCubit(
        progress,
        config: const LetterPuzzleConfig(),
        length: 4,
        items: [PuzzleItem(word: _word, letters: mina)],
        random: Random(7),
      );
      // Fill wrong (tiles as shuffled), check, clear.
      for (var t = 0; t < 4; t++) {
        cubit.placeNext(t);
      }
      cubit.check();
      if (!cubit.state.board.solved) {
        expect(cubit.state.mistakes, 1);
        cubit.clearWrong();
      }
      while (!cubit.state.board.solved) {
        cubit.hint();
      }
      await cubit.next();
      expect(cubit.state.finished, isTrue);
      final mistakes = cubit.state.mistakes;
      expect(cubit.state.stars, const LetterPuzzleConfig().starsFor(mistakes));
      verify(
        () => progress.saveStars(LetterPuzzleCubit.id, '4', cubit.state.stars),
      ).called(1);
    });

    test('stars: 0-2 mistakes = 3, 3-5 = 2, more = 1', () {
      const c = LetterPuzzleConfig();
      expect([0, 2, 3, 5, 6, 20].map(c.starsFor), [3, 3, 2, 2, 1, 1]);
    });
  });

  test('every word in letter_puzzle.json uses known letters and fits its '
      'length', () {
    final config = LetterPuzzleConfig.fromJson(
      jsonDecode(
        File('assets/content/games/letter_puzzle.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final letters = jsonDecode(
      File('assets/content/letters.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ids = {
      for (final l in letters['letters'] as List) (l as Map)['id'] as String,
    };
    for (final n in config.lengths) {
      final words = config.words[n] ?? const [];
      expect(
        words.length,
        greaterThanOrEqualTo(config.wordsPerRound),
        reason: 'length $n',
      );
      for (final w in words) {
        expect(w.letters.length, n, reason: w.ar);
        expect(ids.containsAll(w.letters), isTrue, reason: w.ar);
      }
    }
  });
}

const _word = PuzzleWord(
  ar: 'مينا',
  en: 'Mina',
  letters: ['mi', 'ita', 'ni', 'alpha'],
);

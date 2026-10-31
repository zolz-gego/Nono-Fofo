import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/letter_puzzle/domain/letter_puzzle_config.dart';
import 'package:nonofofo/features/games/letter_puzzle/presentation/letter_puzzle_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/games/where_letter/domain/gap_question.dart';
import 'package:nonofofo/features/games/where_letter/domain/where_letter_config.dart';
import 'package:nonofofo/features/games/where_letter/presentation/where_letter_cubit.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Progress extends Mock implements GameProgressRepository {}

CopticLetter _l(String id, String small, List<String> ar) => CopticLetter(
  id: id,
  small: small,
  capital: small,
  names: {'ar': id},
  sounds: {'ar': ar},
);

void main() {
  final mi = _l('mi', 'ⲙ', ['م']);
  final yta = _l('yta', 'ⲏ', ['ي', 'ـِ']);
  final ni = _l('ni', 'ⲛ', ['ن']);
  final iota = _l('iota', 'ⲓ', ['ي']); // also says ي: never a wrong option
  final ro = _l('ro', 'ⲣ', ['ر']);
  final alpha = _l('alpha', 'ⲁ', ['ا', 'ـَ']);
  final alphabet = [mi, yta, ni, iota, ro, alpha];

  const mina = PuzzleWord(
    text: 'مينا',
    letters: ['mi', 'yta', 'ni', 'alpha'],
    sounds: ['م', 'ي', 'ن', 'ا'],
  );
  const words = [
    mina,
    PuzzleWord(text: 'رب', letters: ['ro'], sounds: ['ر']),
  ];
  final item = PuzzleItem(word: mina, letters: [mi, yta, ni, alpha]);

  GapMaker maker() =>
      GapMaker(alphabet: alphabet, words: words, languageCode: 'ar');

  /// A question whose gap is at [gap].
  GapQuestion at(int gap) {
    for (var seed = 0; ; seed++) {
      final q = maker().make(item, Random(seed));
      if (q.gap == gap) return q;
    }
  }

  group('GapMaker', () {
    test('wrong options never also fit', () {
      for (var seed = 0; seed < 50; seed++) {
        final q = maker().make(item, Random(seed));
        expect(q.letterOptions, hasLength(3));
        expect(q.letterOptions.toSet(), hasLength(3));
        expect(q.letterOptions, contains(q.answer));
        expect(q.soundOptions, hasLength(3));
        expect(q.soundOptions.toSet(), hasLength(3));
        expect(q.soundOptions, contains(q.sound));
        expect(q.sound, mina.sounds[q.gap]);
        if (q.answer == yta) {
          expect(q.letterOptions, isNot(contains(iota)));
          // ⲏ can also say kasra: never a wrong sound for it.
          expect(q.soundOptions, isNot(contains('ـِ')));
        }
      }
    });
  });

  group('GapQuestion', () {
    test('right letter, then right sound, finishes the word', () {
      var q = at(1);
      final r1 = q.pick(q.letterOptions.indexOf(yta))!;
      expect(r1.right, isTrue);
      q = r1.question;
      expect(q.step, GapStep.sound);
      final r2 = q.pick(q.soundOptions.indexOf('ي'))!;
      expect(r2.right, isTrue);
      expect(r2.question.done, isTrue);
    });

    test('a wrong pick stays red and can\'t be picked again', () {
      final q = at(0);
      final wrong = q.letterOptions.indexWhere((l) => l != mi);
      final r = q.pick(wrong)!;
      expect(r.right, isFalse);
      expect(r.question.markAt(wrong), OptionMark.wrong);
      expect(r.question.pick(wrong), isNull);
    });

    test('hints take the wrong options away, never the right one', () {
      var q = at(2);
      q = q.hint(Random(1))!;
      q = q.hint(Random(2))!;
      expect(q.hint(Random(3)), isNull);
      expect(q.canHint, isFalse);
      expect(q.markAt(q.letterOptions.indexOf(ni)), OptionMark.none);
    });
  });

  test('cubit: wrong picks and hints are mistakes, stars at the end', () async {
    final progress = _Progress();
    when(
      () => progress.saveStars(any(), any(), any()),
    ).thenAnswer((_) async => true);
    final cubit = WhereLetterCubit(
      progress,
      config: const WhereLetterConfig(),
      length: 4,
      items: [item],
      maker: maker(),
      random: Random(4),
    );
    var q = cubit.state.question;
    cubit.pick(q.letterOptions.indexWhere((l) => l != q.answer));
    expect(cubit.state.event, WhereLetterEvent.wrong);
    cubit.hint();
    expect(cubit.state.mistakes, 2);
    cubit.pick(q.letterOptions.indexOf(q.answer));
    expect(cubit.state.event, WhereLetterEvent.letterRight);
    q = cubit.state.question;
    cubit.pick(q.soundOptions.indexOf(q.sound));
    expect(cubit.state.event, WhereLetterEvent.wordDone);
    await cubit.next();
    expect(cubit.state.finished, isTrue);
    expect(cubit.state.stars, 3);
    verify(() => progress.saveStars(WhereLetterCubit.id, '4', 3)).called(1);
  });
}

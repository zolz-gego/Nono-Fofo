import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/cards/domain/card_grid.dart';
import 'package:nonofofo/features/games/cards/domain/cards_config.dart';
import 'package:nonofofo/features/games/cards/domain/cards_mode.dart';
import 'package:nonofofo/features/games/cards/domain/memory_card.dart';
import 'package:nonofofo/features/games/cards/presentation/cards_cubit.dart';
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

void main() {
  setUpAll(
    () =>
        registerFallbackValue(const TimedRecord(time: Duration.zero, moves: 0)),
  );

  group('dealCards', () {
    test('deals capital + small pairs', () {
      final cards = dealCards(
        alphabet: _alphabet,
        count: 16,
        random: Random(1),
      );
      expect(cards, hasLength(16));
      final byLetter = <CopticLetter, List<MemoryCard>>{};
      for (final c in cards) {
        byLetter.putIfAbsent(c.letter, () => []).add(c);
      }
      expect(byLetter, hasLength(8));
      for (final pair in byLetter.values) {
        expect(pair.map((c) => c.face).toSet(), {
          CardFace.capital,
          CardFace.small,
        });
      }
    });

    test('sound mode deals a letter card and a sound card', () {
      final cards = dealCards(
        alphabet: _alphabet,
        count: 8,
        mode: CardsMode.sounds,
        random: Random(2),
      );
      for (final c in cards) {
        expect(
          cards.where((o) => o.letter == c.letter).map((o) => o.face).toSet(),
          {CardFace.letter, CardFace.sound},
        );
      }
    });

    test('64 cards use the whole alphabet', () {
      final cards = dealCards(alphabet: _alphabet, count: 64);
      expect(cards.map((c) => c.letter).toSet(), hasLength(32));
    });
  });

  group('CardGrid', () {
    test('fits every card inside the area, no overlap', () {
      for (final n in [4, 8, 16, 32, 64]) {
        for (final area in const [
          Size(900, 680),
          Size(360, 640),
          Size(800, 330),
        ]) {
          final grid = CardGrid.fit(n, area);
          final rects = [for (var i = 0; i < n; i++) grid.cardRect(i, n)];
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(-0.01), reason: '$n in $area');
            expect(r.top, greaterThanOrEqualTo(-0.01));
            expect(r.right, lessThanOrEqualTo(area.width + 0.01));
            expect(r.bottom, lessThanOrEqualTo(area.height + 0.01));
          }
          for (var i = 1; i < n; i++) {
            expect(rects[i].overlaps(rects[i - 1].deflate(0.5)), isFalse);
          }
        }
      }
    });
  });

  group('sound cards', () {
    CopticLetter said(String id, List<String> ar, List<String> en) =>
        CopticLetter(
          id: id,
          small: id,
          capital: id.toUpperCase(),
          names: {'en': id},
          sounds: {'ar': ar, 'en': en},
        );
    MemoryCard card(CopticLetter l, CardFace face, {String soundless = ''}) =>
        MemoryCard(letter: l, face: face, soundless: soundless);
    final vida = said('vida', ['ب', 'ڤ'], ['b', 'v']);
    final ei = said('ei', ['ي'], ['e']);
    final ita = said('ita', ['ي'], ['y']);

    test('a sound card shows every sound, in the UI language', () {
      expect(card(vida, CardFace.sound).sounds('ar'), 'ب / ڤ');
      expect(card(vida, CardFace.sound).sounds('en'), 'b / v');
      const so = CopticLetter(id: 'so', small: '6', capital: '^', names: {});
      expect(card(so, CardFace.sound, soundless: '6').sounds('ar'), '6');
    });

    test('the letter card shows both forms', () {
      expect(card(vida, CardFace.letter).glyph, 'VIDA vida');
    });

    test('a letter pairs with any sound card that looks the same', () {
      final eiLetter = card(ei, CardFace.letter);
      expect(eiLetter.pairsWith(card(ei, CardFace.sound)), isTrue);
      expect(eiLetter.pairsWith(card(ita, CardFace.sound)), isTrue);
      // In English Ei says "e" and Ita "y": different cards.
      expect(
        eiLetter.pairsWith(card(ita, CardFace.sound), languageCode: 'en'),
        isFalse,
      );
      expect(eiLetter.pairsWith(card(vida, CardFace.sound)), isFalse);
      expect(eiLetter.pairsWith(card(ita, CardFace.letter)), isFalse);
    });

    test('best times are saved under the sounds game', () async {
      final progress = _Progress();
      when(() => progress.bestTime(any(), any())).thenReturn(null);
      when(() => progress.saveTime(any(), any(), any()))
          .thenAnswer((_) async => true);
      final cubit = CardsCubit(
        progress,
        mode: CardsMode.sounds,
        cards: [card(ei, CardFace.letter), card(ita, CardFace.sound)],
      );
      await cubit.flip(0);
      await cubit.flip(1);
      expect(cubit.state.solved, isTrue);
      verify(() => progress.saveTime('soundCards', '2', any())).called(1);
      await cubit.close();
    });
  });

  test('phones drop the levels with too many cards', () {
    const config = CardsConfig(phoneMaxCards: 32, smallScreenWidth: 600);
    expect(config.levelsFor(390), [4, 8, 16, 32]);
    expect(config.levelsFor(800), [4, 8, 16, 32, 64]);
  });

  group('CardsCubit', () {
    late _Progress progress;
    late List<MemoryCard> cards;
    late CardsCubit cubit;

    // a-capital, b-capital, a-small, b-small.
    MemoryCard card(String id, CardFace face) =>
        MemoryCard(letter: _letter(id), face: face);

    setUp(() {
      progress = _Progress();
      when(() => progress.bestTime(any(), any())).thenReturn(null);
      when(() => progress.saveTime(any(), any(), any()))
          .thenAnswer((_) async => true);
      cards = [
        card('a', CardFace.capital),
        card('b', CardFace.capital),
        card('a', CardFace.small),
        card('b', CardFace.small),
      ];
      cubit = CardsCubit(progress, cards: cards);
    });

    tearDown(() => cubit.close());

    test('a mismatch locks the table until the cards turn back', () async {
      await cubit.flip(0);
      expect(cubit.state.event, CardsEvent.flipped);
      expect(cubit.state.started, isTrue);
      await cubit.flip(1);
      expect(cubit.state.event, CardsEvent.mismatch);
      expect(cubit.state.moves, 1);
      expect(cubit.state.canFlip(2), isFalse);
      cubit.hideMismatch();
      expect(cubit.state.cards.where((c) => c.faceUp), isEmpty);
      expect(cubit.state.canFlip(0), isTrue);
    });

    test('a pair stays up; the last pair solves and saves the time', () async {
      await cubit.flip(0);
      await cubit.flip(2);
      expect(cubit.state.event, CardsEvent.match);
      expect(cubit.state.pairsFound, 1);
      expect(cubit.state.canFlip(0), isFalse);
      await cubit.flip(1);
      await cubit.flip(3);
      expect(cubit.state.event, CardsEvent.solved);
      expect(cubit.state.solved, isTrue);
      expect(cubit.state.moves, 2);
      expect(cubit.state.newRecord, isTrue);
      verify(() => progress.saveTime('cards', '4', any())).called(1);
    });

    test('a slower run is not a new record', () async {
      when(() => progress.bestTime(any(), any()))
          .thenReturn(const TimedRecord(time: Duration.zero, moves: 1));
      for (final i in [0, 2, 1, 3]) {
        await cubit.flip(i);
      }
      expect(cubit.state.newRecord, isFalse);
    });

    test('the same card cannot be turned twice', () async {
      await cubit.flip(0);
      await cubit.flip(0);
      expect(cubit.state.moves, 0);
      expect(cubit.state.open, 0);
    });
  });

  test('TimedRecord: faster wins, then fewer moves', () {
    const a = TimedRecord(time: Duration(seconds: 30), moves: 10);
    expect(
      const TimedRecord(time: Duration(seconds: 29), moves: 20).beats(a),
      isTrue,
    );
    expect(
      const TimedRecord(time: Duration(milliseconds: 30500), moves: 9).beats(a),
      isTrue,
    );
    expect(
      const TimedRecord(time: Duration(seconds: 31), moves: 1).beats(a),
      isFalse,
    );
    expect(formatClock(const Duration(seconds: 65)), '1:05');
  });
}

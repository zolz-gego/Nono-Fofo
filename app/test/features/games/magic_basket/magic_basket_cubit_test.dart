import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/magic_basket/domain/magic_basket_config.dart';
import 'package:nonofofo/features/games/magic_basket/domain/magic_basket_round.dart';
import 'package:nonofofo/features/games/magic_basket/presentation/magic_basket_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Progress extends Mock implements GameProgressRepository {}

void main() {
  const vida = CopticLetter(
    id: 'vida',
    small: 'b',
    capital: 'B',
    names: {'ar': 'بيتا'},
    sounds: {
      'ar': ['ب', 'ڤ'],
    },
  );
  const mi = CopticLetter(
    id: 'mi',
    small: 'm',
    capital: 'M',
    names: {'ar': 'مي'},
    sounds: {
      'ar': ['م'],
    },
  );

  test('a full basket with every sound finishes and saves the stars', () async {
    final progress = _Progress();
    when(
      () => progress.saveStars(any(), any(), any()),
    ).thenAnswer((_) async => true);
    final cubit = MagicBasketCubit(
      MagicBasketRound.start(
        config: const MagicBasketConfig(catchesToWin: 3),
        target: vida,
        pool: const [vida, mi],
        language: 'ar',
      ),
      progress,
    );

    expect(cubit.pick('م'), BasketCatch.wrong);
    expect(cubit.pick('ب'), BasketCatch.correct);
    await cubit.landed();
    expect(cubit.pick('ب'), BasketCatch.correct);
    await cubit.landed();
    // One slot left and ڤ still missing: another ب doesn't count.
    expect(cubit.pick('ب'), BasketCatch.notNeeded);
    expect(cubit.state.event, BasketEvent.notNeeded);
    expect(cubit.pick('ڤ'), BasketCatch.correct);
    await cubit.landed();

    expect(cubit.state.event, BasketEvent.finished);
    expect(cubit.state.isNewBest, isTrue);
    verify(() => progress.saveStars('magicBasket', 'vida', 2)).called(1);
  });
}

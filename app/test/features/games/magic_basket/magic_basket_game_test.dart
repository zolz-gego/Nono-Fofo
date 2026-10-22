import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/core/assets/json_asset_loader.dart';
import 'package:nonofofo/core/domain/character_id.dart';
import 'package:nonofofo/engines/characters/data/character_repository_impl.dart';
import 'package:nonofofo/engines/sound/application/sound_service.dart';
import 'package:nonofofo/engines/sound/domain/sound_event.dart';
import 'package:nonofofo/features/games/magic_basket/data/magic_basket_config_repository.dart';
import 'package:nonofofo/features/games/magic_basket/domain/magic_basket_round.dart';
import 'package:nonofofo/features/games/magic_basket/game/apple_component.dart';
import 'package:nonofofo/features/games/magic_basket/game/magic_basket_game.dart';
import 'package:nonofofo/features/games/magic_basket/presentation/magic_basket_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/data/letter_repository_impl.dart';
import 'package:nonofofo/features/levels/domain/game_level.dart';

class _Sound extends Mock implements SoundService {}

class _Progress extends Mock implements GameProgressRepository {}

void main() {
  setUpAll(() => registerFallbackValue(SoundEvent.tap));

  testWidgets('with the pictures, a right apple lands in the basket', (
    tester,
  ) async {
    final sound = _Sound();
    when(() => sound.play(any())).thenAnswer((_) async {});
    late MagicBasketGame game;
    late MagicBasketCubit cubit;
    await tester.runAsync(() async {
      final loader = JsonAssetLoader(rootBundle);
      final roster = await CharacterRepositoryImpl(loader).loadRoster();
      final config = await MagicBasketConfigRepository(loader).load();
      final letters = await LetterRepositoryImpl(loader).lettersOf(
        GameLevel.two,
      );
      cubit = MagicBasketCubit(
        MagicBasketRound.start(
          config: config,
          target: letters.firstWhere((l) => l.id == 'vida'),
          pool: letters,
          language: 'en',
        ),
        _Progress(),
      );
      game = MagicBasketGame(
        cubit: cubit,
        hero: CharacterId.fofo,
        roster: roster,
        sound: sound,
        arabic: false,
        random: Random(4),
      );
      game.onGameResize(Vector2(1280, 800));
      // Same start-up flame_test does (no flame_test dependency here).
      // ignore: invalid_use_of_internal_member
      await game.load();
      // ignore: invalid_use_of_internal_member
      game.mount();
      game.update(0);
      await game.ready();
    });

    expect(game.treePicture, isNotNull);
    expect(game.applePicture, isNotNull);
    expect(game.basketPicture, isNotNull);
    // The brother sits on the picture's branch, at the start side.
    expect(game.layout.seatPoint.dx, lessThan(game.layout.width / 2));

    void run(double seconds) {
      for (var t = 0.0; t < seconds; t += 1 / 30) {
        game.update(1 / 30);
      }
    }

    // Follow the first right apple until it is caught.
    for (var i = 0; i < 40 && cubit.state.round.caught.isEmpty; i++) {
      final right = game.children
          .whereType<AppleComponent>()
          .where(
            (a) =>
                a.state == AppleState.falling &&
                cubit.round.isRight(a.sound),
          )
          .firstOrNull;
      if (right != null) game.aimAt(right.x);
      run(0.5);
    }
    expect(cubit.state.round.caught, isNotEmpty);
    expect(
      game.children.whereType<AppleComponent>().where(
        (a) => a.state == AppleState.basket,
      ),
      isNotEmpty,
    );
    await cubit.close();
  });
}

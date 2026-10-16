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
import 'package:nonofofo/features/games/balloons/domain/balloons_config.dart';
import 'package:nonofofo/features/games/balloons/domain/balloons_round.dart';
import 'package:nonofofo/features/games/balloons/game/balloon_component.dart';
import 'package:nonofofo/features/games/balloons/game/balloons_game.dart';
import 'package:nonofofo/features/games/balloons/presentation/balloons_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';

class _Sound extends Mock implements SoundService {}

class _Progress extends Mock implements GameProgressRepository {}

void main() {
  setUpAll(() => registerFallbackValue(SoundEvent.tap));

  testWidgets('a correct balloon joins the bunch, a wrong one pops', (
    tester,
  ) async {
    final sound = _Sound();
    when(() => sound.play(any())).thenAnswer((_) async {});
    when(() => sound.playKey(any())).thenAnswer((_) async {});
    final progress = _Progress();
    when(() => progress.saveStars(any(), any(), any()))
        .thenAnswer((_) async => true);

    final letters = [
      for (final k in ['a', 'b', 'e', 'z'])
        CopticLetter(id: k, small: k, capital: k.toUpperCase(), names: {}),
    ];
    final cubit = BalloonsCubit(
      BalloonsRound.start(
        config: const BalloonsConfig(catchesToWin: 2),
        target: letters.first,
        pool: letters,
        random: Random(1),
      ),
      progress,
    );

    late BalloonsGame game;
    await tester.runAsync(() async {
      final roster = await CharacterRepositoryImpl(
        JsonAssetLoader(rootBundle),
      ).loadRoster();
      game = BalloonsGame(
        cubit: cubit,
        hero: CharacterId.fofo,
        roster: roster,
        sound: sound,
        random: Random(2),
      );
      game.onGameResize(Vector2(1280, 758));
      // Same start-up flame_test does (no flame_test dependency here).
      // ignore: invalid_use_of_internal_member
      await game.load();
      // ignore: invalid_use_of_internal_member
      game.mount();
      game.update(0);
      await game.ready();
    });

    List<BalloonComponent> balloons() =>
        game.children.whereType<BalloonComponent>().toList();
    void run(double seconds) {
      for (var t = 0.0; t < seconds; t += 1 / 30) {
        game.update(1 / 30);
      }
    }

    expect(balloons(), isNotEmpty);

    // Correct one: the buddy runs, jumps, hands it over; it ends in the bunch.
    final good = balloons().firstWhere((b) => b.letter == letters.first);
    game.balloonTapped(good);
    run(4);
    expect(cubit.state.round.caught, 1);
    expect(cubit.state.landed, 1);
    expect(good.state, BalloonState.bunch);

    // Wrong one: counted as a mistake and popped.
    final bad = balloons().firstWhere(
      (b) => b.isRising && b.letter != letters.first,
    );
    game.balloonTapped(bad);
    run(5);
    expect(cubit.state.round.wrongCatches, 1);
    expect(bad.isMounted, isFalse);

    await cubit.close();
  });
}

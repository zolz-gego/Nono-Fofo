import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_page.dart';
import '../features/home/presentation/home_page.dart';
import '../core/l10n/l10n.dart';
import '../features/games/adventure/presentation/adventure_page.dart';
import '../features/games/balloons/presentation/balloons_cubit.dart';
import '../features/games/balloons/presentation/balloons_page.dart';
import '../features/games/cards/presentation/cards_level_page.dart';
import '../features/games/cards/presentation/cards_page.dart';
import '../features/games/challenge/presentation/challenge_picker_page.dart';
import '../features/games/fishing/presentation/fishing_cubit.dart';
import '../features/games/fishing/presentation/fishing_page.dart';
import '../features/games/letter_hunt/presentation/letter_pick_page.dart';
import '../features/games/monastery/presentation/monastery_level_page.dart';
import '../features/games/monastery/presentation/monastery_page.dart';
import '../features/games/snakes_ladders/presentation/snakes_page.dart';
import '../features/games/writing/presentation/writing_cubit.dart';
import '../features/games/writing/presentation/writing_page.dart';
import '../features/levels/domain/game_level.dart';
import '../features/levels/presentation/level_games_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const about = '/about';

  /// A level's games. Needs the [PlayerSetup] as `extra`; without it
  /// (e.g. after a browser refresh) it goes back home.
  static const level = '/level';

  /// Fishing: pick a letter (extra: [PlayerSetup]), then play
  /// (extra: [LetterHuntArgs]).
  static const fishing = '/level/fishing';
  static const fishingPlay = '/level/fishing/play';

  /// Balloons: pick a letter (extra: [PlayerSetup]), then play
  /// (extra: [LetterHuntArgs]).
  static const balloons = '/level/balloons';
  static const balloonsPlay = '/level/balloons/play';

  /// Write the letter (Grandpa's house): pick a letter (extra:
  /// [PlayerSetup]), then write it (extra: [LetterHuntArgs]).
  static const writing = '/level/writing';
  static const writingPlay = '/level/writing/play';

  /// Grandpa's Cards (Alexandria): pick how many cards (extra:
  /// [PlayerSetup]), then play (extra: [CardsArgs]).
  static const cards = '/level/cards';
  static const cardsPlay = '/level/cards/play';

  /// Search the Monastery: pick how many letters hide (extra:
  /// [PlayerSetup]; phones skip this), then play (extra: [MonasteryArgs]).
  static const monastery = '/level/monastery';
  static const monasteryPlay = '/level/monastery/play';

  /// The level's challenge: pick a challenge game (extra: [PlayerSetup]).
  static const challenge = '/level/challenge';

  /// Snakes & Ladders by the Pyramids (extra: [PlayerSetup]).
  static const challengeSnakes = '/level/challenge/snakes';

  /// Nono & Fofo Adventure, the side-scroller (extra: [PlayerSetup]).
  static const challengeAdventure = '/level/challenge/adventure';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: AppRoutes.level,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          LevelGamesPage(setup: state.extra! as PlayerSetup),
    ),
    GoRoute(
      path: AppRoutes.fishing,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) => LetterPickPage(
        setup: state.extra! as PlayerSetup,
        gameId: FishingCubit.id,
        title: context.l10n.gameFishing,
        prompt: context.l10n.pickLetter,
        playRoute: AppRoutes.fishingPlay,
      ),
    ),
    GoRoute(
      path: AppRoutes.fishingPlay,
      redirect: (context, state) =>
          state.extra is LetterHuntArgs ? null : AppRoutes.home,
      builder: (context, state) =>
          FishingPage(args: state.extra! as LetterHuntArgs),
    ),
    GoRoute(
      path: AppRoutes.balloons,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) => LetterPickPage(
        setup: state.extra! as PlayerSetup,
        gameId: BalloonsCubit.id,
        title: context.l10n.gameBalloons,
        prompt: context.l10n.balloonsPickLetter,
        playRoute: AppRoutes.balloonsPlay,
      ),
    ),
    GoRoute(
      path: AppRoutes.balloonsPlay,
      redirect: (context, state) =>
          state.extra is LetterHuntArgs ? null : AppRoutes.home,
      builder: (context, state) =>
          BalloonsPage(args: state.extra! as LetterHuntArgs),
    ),
    GoRoute(
      path: AppRoutes.writing,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) => LetterPickPage(
        setup: state.extra! as PlayerSetup,
        gameId: WritingCubit.id,
        title: context.l10n.gameWriteLetter,
        prompt: context.l10n.writingPickLetter,
        playRoute: AppRoutes.writingPlay,
        passFail: true,
        allLetters: true,
      ),
    ),
    GoRoute(
      path: AppRoutes.writingPlay,
      redirect: (context, state) =>
          state.extra is LetterHuntArgs ? null : AppRoutes.home,
      builder: (context, state) =>
          WritingPage(args: state.extra! as LetterHuntArgs),
    ),
    GoRoute(
      path: AppRoutes.cards,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          CardsLevelPage(setup: state.extra! as PlayerSetup),
    ),
    GoRoute(
      path: AppRoutes.cardsPlay,
      redirect: (context, state) =>
          state.extra is CardsArgs ? null : AppRoutes.home,
      builder: (context, state) => CardsPage(args: state.extra! as CardsArgs),
    ),
    GoRoute(
      path: AppRoutes.monastery,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          MonasteryLevelPage(setup: state.extra! as PlayerSetup),
    ),
    GoRoute(
      path: AppRoutes.monasteryPlay,
      redirect: (context, state) =>
          state.extra is MonasteryArgs ? null : AppRoutes.home,
      builder: (context, state) =>
          MonasteryPage(args: state.extra! as MonasteryArgs),
    ),
    GoRoute(
      path: AppRoutes.challenge,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          ChallengePickerPage(setup: state.extra! as PlayerSetup),
    ),
    GoRoute(
      path: AppRoutes.challengeSnakes,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          SnakesPage(setup: state.extra! as PlayerSetup),
    ),
    GoRoute(
      path: AppRoutes.challengeAdventure,
      redirect: (context, state) =>
          state.extra is PlayerSetup ? null : AppRoutes.home,
      builder: (context, state) =>
          AdventurePage(setup: state.extra! as PlayerSetup),
    ),
  ],
);

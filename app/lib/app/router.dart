import 'package:flutter/widgets.dart';
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
    _withExtra<PlayerSetup>(
      AppRoutes.level,
      (context, extra) => LevelGamesPage(setup: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.fishing,
      (context, extra) => LetterPickPage(
        setup: extra,
        gameId: FishingCubit.id,
        title: context.l10n.gameFishing,
        prompt: context.l10n.pickLetter,
        playRoute: AppRoutes.fishingPlay,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.fishingPlay,
      (context, extra) => FishingPage(args: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.balloons,
      (context, extra) => LetterPickPage(
        setup: extra,
        gameId: BalloonsCubit.id,
        title: context.l10n.gameBalloons,
        prompt: context.l10n.balloonsPickLetter,
        playRoute: AppRoutes.balloonsPlay,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.balloonsPlay,
      (context, extra) => BalloonsPage(args: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.writing,
      (context, extra) => LetterPickPage(
        setup: extra,
        gameId: WritingCubit.id,
        title: context.l10n.gameWriteLetter,
        prompt: context.l10n.writingPickLetter,
        playRoute: AppRoutes.writingPlay,
        passFail: true,
        allLetters: true,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.writingPlay,
      (context, extra) => WritingPage(args: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.cards,
      (context, extra) => CardsLevelPage(setup: extra),
    ),
    _withExtra<CardsArgs>(
      AppRoutes.cardsPlay,
      (context, extra) => CardsPage(args: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.monastery,
      (context, extra) => MonasteryLevelPage(setup: extra),
    ),
    _withExtra<MonasteryArgs>(
      AppRoutes.monasteryPlay,
      (context, extra) => MonasteryPage(args: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.challenge,
      (context, extra) => ChallengePickerPage(setup: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.challengeSnakes,
      (context, extra) => SnakesPage(setup: extra),
    ),
    _withExtra<PlayerSetup>(
      AppRoutes.challengeAdventure,
      (context, extra) => AdventurePage(setup: extra),
    ),
  ],
);

/// A route whose page needs [T] as `extra`. Without it (a browser refresh,
/// or browser Back to a page that was pushed) the app goes home instead of
/// building the page.
GoRoute _withExtra<T>(
  String path,
  Widget Function(BuildContext context, T extra) builder,
) => GoRoute(
  path: path,
  redirect: (context, state) => state.extra is T ? null : AppRoutes.home,
  builder: (context, state) {
    final extra = state.extra;
    return extra is T ? builder(context, extra) : const _GoHome();
  },
);

/// Shown for a frame when a page lost its `extra` after the redirect ran:
/// goes home right away.
class _GoHome extends StatefulWidget {
  const _GoHome();

  @override
  State<_GoHome> createState() => _GoHomeState();
}

class _GoHomeState extends State<_GoHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

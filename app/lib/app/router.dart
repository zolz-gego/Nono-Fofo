import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_page.dart';
import '../features/home/presentation/home_page.dart';
import '../core/l10n/l10n.dart';
import '../core/widgets/app_top_bar.dart';
import '../features/games/adventure/presentation/adventure_page.dart';
import '../features/games/balloons/presentation/balloons_cubit.dart';
import '../features/games/balloons/presentation/balloons_page.dart';
import '../features/games/cards/presentation/cards_level_page.dart';
import '../features/games/cards/presentation/cards_page.dart';
import '../features/games/challenge/presentation/challenge_picker_page.dart';
import '../features/games/fishing/presentation/fishing_cubit.dart';
import '../features/games/fishing/presentation/fishing_page.dart';
import '../features/games/letter_hunt/presentation/letter_pick_page.dart';
import '../features/games/letter_puzzle/presentation/letter_puzzle_level_page.dart';
import '../features/games/letter_puzzle/presentation/letter_puzzle_page.dart';
import '../features/games/match_letters/presentation/match_letters_cubit.dart';
import '../features/games/match_letters/presentation/match_letters_page.dart';
import '../features/games/where_letter/presentation/where_letter_cubit.dart';
import '../features/games/where_letter/presentation/where_letter_page.dart';
import '../features/games/magic_basket/presentation/magic_basket_cubit.dart';
import '../features/games/magic_basket/presentation/magic_basket_page.dart';
import '../features/games/monastery/presentation/monastery_level_page.dart';
import '../features/games/monastery/presentation/monastery_page.dart';
import '../features/games/snakes_ladders/presentation/snakes_page.dart';
import '../features/games/writing/presentation/writing_cubit.dart';
import '../features/games/writing/presentation/writing_page.dart';
import '../features/levels/domain/game_level.dart';
import '../features/levels/presentation/level_games_page.dart';
import '../features/profile/domain/player_profile.dart';
import '../features/profile/presentation/profile_cubit.dart';
import '../features/profile/presentation/profile_dialog.dart';

/// Every page has its own URL, so a game's link can be shared and opened
/// directly (e.g. `/level1/cards`). Pages that need the player get it from
/// the saved profile; with none saved, the profile pop-up comes first.
abstract final class AppRoutes {
  static const home = '/';
  static const about = '/about';

  /// A level's games on the road, e.g. `/level1`.
  static String level(GameLevel level) => '/level${level.number}';

  // A game's page is its picker (letter, card count, word length…); its
  // `/play` page needs the picked args as `extra`, so opening it directly
  // (a shared link, a browser refresh) goes back to the picker.

  /// Fishing: pick a letter, then play (extra: [LetterHuntArgs]).
  static const fishing = '/level1/fishing';
  static const fishingPlay = '/level1/fishing/play';

  /// Write the letter (Grandpa's house): pick a letter, then write it
  /// (extra: [LetterHuntArgs]).
  static const writing = '/level1/writing';
  static const writingPlay = '/level1/writing/play';

  /// Balloons: pick a letter, then play (extra: [LetterHuntArgs]).
  static const balloons = '/level1/balloons';
  static const balloonsPlay = '/level1/balloons/play';

  /// Grandpa's Cards (Alexandria): pick how many cards, then play (extra:
  /// [CardsArgs]).
  static const cards = '/level1/cards';
  static const cardsPlay = '/level1/cards/play';

  /// Search the Monastery: pick how many letters hide (phones skip this),
  /// then play (extra: [MonasteryArgs]).
  static const monastery = '/level1/monastery';
  static const monasteryPlay = '/level1/monastery/play';

  /// The level's challenge: pick a challenge game.
  static const challenge = '/level1/challenge';

  /// Snakes & Ladders by the Pyramids.
  static const challengeSnakes = '/level1/challenge/snakes';

  /// Nono & Fofo Adventure, the side-scroller.
  static const challengeAdventure = '/level1/challenge/adventure';

  /// Magic basket (Level 2, sounds): pick a letter, then catch its sounds
  /// (extra: [LetterHuntArgs]).
  static const magicBasket = '/level2/magic-basket';
  static const magicBasketPlay = '/level2/magic-basket/play';

  /// Match the letters (Level 2, the Pyramids): pick a word length, then
  /// match 10 words (extra: [LetterPuzzleArgs]).
  static const matchLetters = '/level2/match-letters';
  static const matchLettersPlay = '/level2/match-letters/play';

  /// Letter puzzle (Level 2, the church): pick a word length, then spell 10
  /// words (extra: [LetterPuzzleArgs]).
  static const letterPuzzle = '/level2/letter-puzzle';
  static const letterPuzzlePlay = '/level2/letter-puzzle/play';

  /// Where's the letter (Level 2, the church): pick a word length, then
  /// fill the gap in 10 words (extra: [LetterPuzzleArgs]).
  static const whereLetter = '/level2/where-letter';
  static const whereLetterPlay = '/level2/where-letter/play';
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
    for (final level in GameLevel.values)
      _withPlayer(
        level,
        AppRoutes.level(level),
        (context, setup) => LevelGamesPage(setup: setup),
      ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.fishing,
      (context, setup) => LetterPickPage(
        setup: setup,
        gameId: FishingCubit.id,
        title: context.l10n.gameFishing,
        prompt: context.l10n.pickLetter,
        playRoute: AppRoutes.fishingPlay,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.fishingPlay,
      AppRoutes.fishing,
      (context, extra) => FishingPage(args: extra),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.balloons,
      (context, setup) => LetterPickPage(
        setup: setup,
        gameId: BalloonsCubit.id,
        title: context.l10n.gameBalloons,
        prompt: context.l10n.balloonsPickLetter,
        playRoute: AppRoutes.balloonsPlay,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.balloonsPlay,
      AppRoutes.balloons,
      (context, extra) => BalloonsPage(args: extra),
    ),
    _withPlayer(
      GameLevel.two,
      AppRoutes.magicBasket,
      (context, setup) => LetterPickPage(
        setup: setup,
        gameId: MagicBasketCubit.id,
        title: context.l10n.gameMagicBasket,
        prompt: context.l10n.magicBasketPickLetter,
        playRoute: AppRoutes.magicBasketPlay,
        bothForms: true,
      ),
    ),
    _withExtra<LetterHuntArgs>(
      AppRoutes.magicBasketPlay,
      AppRoutes.magicBasket,
      (context, extra) => MagicBasketPage(args: extra),
    ),
    _withPlayer(
      GameLevel.two,
      AppRoutes.matchLetters,
      (context, setup) => LetterPuzzleLevelPage(
        setup: setup,
        gameId: MatchLettersCubit.id,
        title: (l10n) => l10n.gameMatchLetters,
        prompt: (l10n) => l10n.matchLettersPickLevel,
        playRoute: AppRoutes.matchLettersPlay,
      ),
    ),
    _withExtra<LetterPuzzleArgs>(
      AppRoutes.matchLettersPlay,
      AppRoutes.matchLetters,
      (context, extra) => MatchLettersPage(args: extra),
    ),
    _withPlayer(
      GameLevel.two,
      AppRoutes.whereLetter,
      (context, setup) => LetterPuzzleLevelPage(
        setup: setup,
        gameId: WhereLetterCubit.id,
        title: (l10n) => l10n.gameWhereLetter,
        prompt: (l10n) => l10n.whereLetterPickLevel,
        playRoute: AppRoutes.whereLetterPlay,
      ),
    ),
    _withExtra<LetterPuzzleArgs>(
      AppRoutes.whereLetterPlay,
      AppRoutes.whereLetter,
      (context, extra) => WhereLetterPage(args: extra),
    ),
    _withPlayer(
      GameLevel.two,
      AppRoutes.letterPuzzle,
      (context, setup) => LetterPuzzleLevelPage(setup: setup),
    ),
    _withExtra<LetterPuzzleArgs>(
      AppRoutes.letterPuzzlePlay,
      AppRoutes.letterPuzzle,
      (context, extra) => LetterPuzzlePage(args: extra),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.writing,
      (context, setup) => LetterPickPage(
        setup: setup,
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
      AppRoutes.writing,
      (context, extra) => WritingPage(args: extra),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.cards,
      (context, setup) => CardsLevelPage(setup: setup),
    ),
    _withExtra<CardsArgs>(
      AppRoutes.cardsPlay,
      AppRoutes.cards,
      (context, extra) => CardsPage(args: extra),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.monastery,
      (context, setup) => MonasteryLevelPage(setup: setup),
    ),
    _withExtra<MonasteryArgs>(
      AppRoutes.monasteryPlay,
      AppRoutes.monastery,
      (context, extra) => MonasteryPage(args: extra),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.challenge,
      (context, setup) => ChallengePickerPage(setup: setup),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.challengeSnakes,
      (context, setup) => SnakesPage(setup: setup),
    ),
    _withPlayer(
      GameLevel.one,
      AppRoutes.challengeAdventure,
      (context, setup) => AdventurePage(setup: setup),
    ),
  ],
);

/// A page of [level] that needs the player: built from the saved profile.
/// With no profile yet (a shared link on a new device) the profile pop-up
/// shows first, then the page.
GoRoute _withPlayer(
  GameLevel level,
  String path,
  Widget Function(BuildContext context, PlayerSetup setup) builder,
) => GoRoute(
  path: path,
  builder: (context, state) => BlocBuilder<ProfileCubit, PlayerProfile?>(
    builder: (context, profile) => profile == null
        ? _AskProfile(level: level)
        // A new profile (from the top bar) rebuilds the page from scratch,
        // so the right brother walks it.
        : KeyedSubtree(
            key: ValueKey(profile),
            child: builder(context, PlayerSetup.from(level, profile)),
          ),
  ),
);

/// A play page that needs [T] (what was picked) as `extra`. Without it (a
/// shared link, a browser refresh, or browser Back to a page that was
/// pushed) the app goes to the game's [picker] instead.
GoRoute _withExtra<T>(
  String path,
  String picker,
  Widget Function(BuildContext context, T extra) builder,
) => GoRoute(
  path: path,
  redirect: (context, state) => state.extra is T ? null : picker,
  builder: (context, state) {
    final extra = state.extra;
    return extra is T ? builder(context, extra) : _GoTo(picker);
  },
);

/// Shown for a frame when a page lost its `extra` after the redirect ran:
/// goes to [location] right away.
class _GoTo extends StatefulWidget {
  const _GoTo(this.location);

  final String location;

  @override
  State<_GoTo> createState() => _GoToState();
}

class _GoToState extends State<_GoTo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A page that asks for the profile first. Saving it shows the page that
/// was opened; closing it goes home. The card is part of the page, not a
/// pushed dialog: the router rebuilds its pages once a link opens, which
/// would drop a dialog pushed on top.
class _AskProfile extends StatelessWidget {
  const _AskProfile({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: context.l10n.levelNumber(level.number),
      onLogoTap: () => context.go(AppRoutes.home),
    ),
    body: Center(
      child: ProfileDialog(
        level: level,
        onDone: (profile) => profile == null
            ? context.go(AppRoutes.home)
            : context.read<ProfileCubit>().save(profile),
      ),
    ),
  );
}

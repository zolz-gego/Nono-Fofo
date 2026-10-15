import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/levels/domain/game_level.dart';
import '../features/levels/presentation/level_games_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const about = '/about';

  /// A level's games. Needs the [PlayerSetup] as `extra`; without it
  /// (e.g. after a browser refresh) it goes back home.
  static const level = '/level';
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
  ],
);

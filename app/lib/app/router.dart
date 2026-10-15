import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_page.dart';
import '../features/home/presentation/home_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const about = '/about';
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
  ],
);

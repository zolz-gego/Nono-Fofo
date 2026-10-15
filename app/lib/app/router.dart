import 'package:go_router/go_router.dart';

import '../features/playground/presentation/playground_page.dart';

abstract final class AppRoutes {
  static const playground = '/';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.playground,
  routes: [
    GoRoute(
      path: AppRoutes.playground,
      builder: (context, state) => const PlaygroundPage(),
    ),
  ],
);

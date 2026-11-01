import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean web links (`/level1/cards`, no `#`), and the address bar follows
  // every page opened, so any page's link can be copied and shared.
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await configureDependencies();
  runApp(const NonoFofoApp());
}

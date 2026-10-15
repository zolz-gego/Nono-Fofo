import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../engines/characters/domain/character_pose.dart';
import '../engines/sound/application/sound_service.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_cubit.dart';
import 'di/injection.dart';
import 'router.dart';

class NonoFofoApp extends StatefulWidget {
  const NonoFofoApp({super.key});

  @override
  State<NonoFofoApp> createState() => _NonoFofoAppState();
}

class _NonoFofoAppState extends State<NonoFofoApp> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => sl<SoundService>().pause(),
    onShow: () => sl<SoundService>().resume(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SoundService>.value(value: sl<SoundService>()),
        RepositoryProvider<CharacterRoster>.value(value: sl<CharacterRoster>()),
      ],
      child: BlocProvider(
        create: (_) => sl<SettingsCubit>(),
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (a, b) => a.languageCode != b.languageCode,
          builder: (context, _) {
            final locale = context.read<SettingsCubit>().locale;
            return MaterialApp.router(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocales.supported,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(locale),
              routerConfig: appRouter,
            );
          },
        ),
      ),
    );
  }
}

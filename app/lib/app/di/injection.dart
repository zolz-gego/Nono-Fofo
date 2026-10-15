import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/assets/json_asset_loader.dart';
import '../../engines/characters/data/character_repository_impl.dart';
import '../../engines/characters/domain/character_pose.dart';
import '../../engines/characters/domain/character_repository.dart';
import '../../engines/sound/application/sound_service.dart';
import '../../engines/sound/data/audioplayers_audio_engine.dart';
import '../../engines/sound/data/sound_repository_impl.dart';
import '../../engines/sound/domain/audio_engine.dart';
import '../../engines/sound/domain/sound_repository.dart';
import '../../features/questions/data/question_parser_registry.dart';
import '../../features/questions/data/question_repository_impl.dart';
import '../../features/questions/domain/load_questions.dart';
import '../../features/questions/domain/question_repository.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/settings_cubit.dart';

/// Service locator. Only the composition root (this file, `app.dart` and
/// page-level widgets) should call `sl`; inner layers get dependencies
/// through their constructors.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
  sl.registerLazySingleton(() => JsonAssetLoader(rootBundle));

  // Sound engine
  sl.registerLazySingleton<SoundRepository>(() => SoundRepositoryImpl(sl()));
  sl.registerLazySingleton<AudioEngine>(AudioplayersAudioEngine.new);
  sl.registerLazySingleton(() => SoundService(sl(), sl()));

  // Character engine
  sl.registerLazySingleton<CharacterRepository>(
      () => CharacterRepositoryImpl(sl()));

  // Settings
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()));
  sl.registerFactory(() => SettingsCubit(sl(), sl()));

  // Questions — register a parser per question type here.
  sl.registerLazySingleton(QuestionParserRegistry.new);
  sl.registerLazySingleton<QuestionRepository>(
      () => QuestionRepositoryImpl(sl(), sl()));
  sl.registerFactory(() => LoadQuestions(sl()));

  // Warm up engines before the first frame.
  await sl<SoundService>().init();
  sl.registerSingleton<CharacterRoster>(
      await sl<CharacterRepository>().loadRoster());
}

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_progress_repository.dart';

class GameProgressRepositoryImpl implements GameProgressRepository {
  const GameProgressRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String game, String letterId) =>
      'progress.$game.$letterId.stars';

  static String _passedKey(String game, String letterId) =>
      'progress.$game.$letterId.passed';

  @override
  int bestStars(String game, String letterId) =>
      _prefs.getInt(_key(game, letterId)) ?? 0;

  @override
  Future<bool> saveStars(String game, String letterId, int stars) async {
    if (stars <= bestStars(game, letterId)) return false;
    await _prefs.setInt(_key(game, letterId), stars);
    return true;
  }

  @override
  bool hasPassed(String game, String letterId) =>
      _prefs.getBool(_passedKey(game, letterId)) ?? false;

  @override
  Future<void> savePassed(String game, String letterId) =>
      _prefs.setBool(_passedKey(game, letterId), true);
}

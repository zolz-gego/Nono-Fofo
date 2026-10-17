import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_progress_repository.dart';
import '../domain/timed_record.dart';

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

  static String _timeKey(String game, String levelKey) =>
      'progress.$game.$levelKey.timeMs';

  static String _movesKey(String game, String levelKey) =>
      'progress.$game.$levelKey.moves';

  @override
  TimedRecord? bestTime(String game, String levelKey) {
    final ms = _prefs.getInt(_timeKey(game, levelKey));
    if (ms == null) return null;
    return TimedRecord(
      time: Duration(milliseconds: ms),
      moves: _prefs.getInt(_movesKey(game, levelKey)) ?? 0,
    );
  }

  @override
  Future<bool> saveTime(
    String game,
    String levelKey,
    TimedRecord record,
  ) async {
    final best = bestTime(game, levelKey);
    if (best != null && !record.beats(best)) return false;
    await _prefs.setInt(_timeKey(game, levelKey), record.time.inMilliseconds);
    await _prefs.setInt(_movesKey(game, levelKey), record.moves);
    return true;
  }
}

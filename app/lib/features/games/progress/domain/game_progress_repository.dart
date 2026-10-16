/// Best result per game and letter, saved on this device.
abstract interface class GameProgressRepository {
  /// Best stars (0 = never finished) for [game] played with [letterId].
  int bestStars(String game, String letterId);

  /// Keeps [stars] if it beats the saved best. Returns true if it did.
  Future<bool> saveStars(String game, String letterId, int stars);

  /// For pass / not-passed games (no stars): has [letterId] ever passed?
  bool hasPassed(String game, String letterId);

  /// Remembers that [letterId] passed in [game].
  Future<void> savePassed(String game, String letterId);
}

/// Best result per game and letter, saved on this device.
abstract interface class GameProgressRepository {
  /// Best stars (0 = never finished) for [game] played with [letterId].
  int bestStars(String game, String letterId);

  /// Keeps [stars] if it beats the saved best. Returns true if it did.
  Future<bool> saveStars(String game, String letterId, int stars);
}

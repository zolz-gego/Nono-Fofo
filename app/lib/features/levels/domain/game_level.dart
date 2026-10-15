import '../../../core/domain/character_id.dart';

/// The playable levels shown on the home page (phase 1 has three).
enum GameLevel {
  one(1),
  two(2),
  three(3);

  const GameLevel(this.number);

  final int number;
}

/// What the child picked before starting a level.
class PlayerSetup {
  const PlayerSetup({
    required this.level,
    required this.name,
    required this.buddy,
  });

  final GameLevel level;
  final String name;

  /// The brother the child plays with; the other one is the opponent.
  final CharacterId buddy;
}

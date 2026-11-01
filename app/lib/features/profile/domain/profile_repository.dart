import 'player_profile.dart';

abstract interface class ProfileRepository {
  /// The saved profile, or null if none was set on this device yet.
  PlayerProfile? read();
  Future<void> save(PlayerProfile profile);
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/character_id.dart';
import '../domain/player_profile.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _name = 'profile.name';
  static const _buddy = 'profile.buddy';

  @override
  PlayerProfile? read() {
    final name = _prefs.getString(_name);
    final buddy = CharacterId.values.asNameMap()[_prefs.getString(_buddy)];
    if (name == null || name.isEmpty || buddy == null) return null;
    return PlayerProfile(name: name, buddy: buddy);
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    await _prefs.setString(_name, profile.name);
    await _prefs.setString(_buddy, profile.buddy.name);
  }
}

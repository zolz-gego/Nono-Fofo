import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/domain/character_id.dart';
import 'package:nonofofo/features/profile/data/profile_repository_impl.dart';
import 'package:nonofofo/features/profile/domain/player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProfileRepositoryImpl> repo([Map<String, Object> saved = const {}]) {
    SharedPreferences.setMockInitialValues(saved);
    return SharedPreferences.getInstance().then(ProfileRepositoryImpl.new);
  }

  test('no profile until one is saved', () async {
    expect((await repo()).read(), isNull);
  });

  test('a saved profile reads back', () async {
    final r = await repo();
    const profile = PlayerProfile(name: 'Mina', buddy: CharacterId.fofo);
    await r.save(profile);
    expect(r.read(), profile);
  });

  test('an unknown buddy reads as no profile', () async {
    final r = await repo({'profile.name': 'Mina', 'profile.buddy': 'zozo'});
    expect(r.read(), isNull);
  });
}

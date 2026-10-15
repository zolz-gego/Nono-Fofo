import 'character_pose.dart';

abstract interface class CharacterRepository {
  Future<CharacterRoster> loadRoster();
}

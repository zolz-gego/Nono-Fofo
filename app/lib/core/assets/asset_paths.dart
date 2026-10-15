/// Every asset path the code knows about. Pipelines in `../tools` write here.
abstract final class AssetPaths {
  /// Round app logo, from tools/brand/process_logo.py.
  static const String logo = 'assets/brand/logo.png';

  static const String characters = 'assets/characters';
  static const String characterManifest = '$characters/manifest.json';

  /// Small still image of one pose, e.g. `characterPose('nono', 'cheer')`.
  static String characterPose(String character, String pose) =>
      '$characters/$character/small/$pose.png';

  /// Card illustration of one game, e.g. `gameImage('fishing')`.
  static String gameImage(String game) => 'assets/games/$game.png';

  static const String audio = 'assets/audio';
  static const String audioManifest = '$audio/manifest.json';

  /// Event -> sound mapping. Edit this to change which sound plays when.
  static const String soundMap = '$audio/sound_map.json';

  /// Coptic letters and which level uses which (edit to add letters).
  static const String letters = 'assets/content/letters.json';

  /// Per-game settings, e.g. `gameConfig('fishing')`.
  static String gameConfig(String game) => 'assets/content/games/$game.json';

  /// One JSON file per question type lives in this folder.
  static const String questions = 'assets/content/questions/';
}

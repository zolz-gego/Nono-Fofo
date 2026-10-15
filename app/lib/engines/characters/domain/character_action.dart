/// Every pose a brother can take. `name` matches the pose key in
/// `assets/characters/manifest.json`.
enum CharacterAction {
  idle,
  cheer,
  wrong,
  hint,
  celebrate,
  encourage,
  run,
  wave,
  write,
  read,
  sleep,
  surprised,

  /// Holding a fishing rod, waiting (fishing game).
  fish,

  /// Pulling the rod up, excited (fishing game).
  reel,
}

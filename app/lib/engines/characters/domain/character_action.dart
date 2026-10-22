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

  /// Jumping with one fist up, grabbing a balloon string (balloons game).
  jump,

  /// Standing with one fist up, holding balloon strings (balloons game).
  hold,

  /// Writing on the chalkboard with a stick of chalk (writing game).
  chalk,

  /// Wiping the chalkboard with a sponge (writing game).
  sponge,

  /// Sitting on a tree branch, legs dangling (Magic basket game).
  sit,

  /// Throwing an apple down from the branch (Magic basket game).
  toss,

  /// Holding a basket in front with both hands (Magic basket game).
  carry;

  /// The pose shown while this one has no picture yet.
  CharacterAction? get fallback => switch (this) {
    chalk => write,
    sponge => encourage,
    sit => idle,
    toss => wave,
    carry => idle,
    _ => null,
  };
}

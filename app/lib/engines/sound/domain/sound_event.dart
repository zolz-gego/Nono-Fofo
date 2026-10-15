/// App-wide moments that make a sound. Code only ever plays these;
/// `assets/audio/sound_map.json` decides which file(s) each one uses
/// (the JSON key is the enum name).
///
/// Game-specific sounds (e.g. `fishing.fish_catch`) are plain string keys in
/// the same JSON, played with `SoundService.playKey`.
enum SoundEvent {
  // UI
  tap,
  back,
  toggle,
  popupOpen,
  popupClose,
  swipe,
  locked,
  unlock,
  select,
  coin,
  // Answers & turns
  correctAnswer,
  correctStreak,
  wrongAnswer,
  tryAgain,
  hint,
  hintRevealed,
  skipTurn,
  yourTurn,
  opponentTurn,
  timerTick,
  timerHurry,
  timeUp,
  countdownBeep,
  countdownGo,
  // Levels & rewards
  levelStart,
  levelComplete,
  levelFailed,
  star1,
  star2,
  star3,
  letterFound,
  placeUnlocked,
  rewardSticker,
  confetti,
  gameWin,
  gameLose,
  gameDraw,
  // Characters
  charIdleTap,
  charRun,
  charDash,
  charJump,
  charLand,
  charThink,
  charSurprise,
  charAppear,
  charTired,
  charSleep,
  charSnore;

  String get key => name;
}

/// Background music slots. `assets/audio/sound_map.json` -> "music" maps each
/// slot to a music id, so a track can be replaced without code changes.
enum MusicTrack {
  map,
  grandpaHouse,
  nile,
  village,
  pyramids,
  monastery,
  alexandria,
  boardGame,
  actionGame,
  raceGame;

  String get key => name;
}

/// Volume channels the parent can control separately.
enum SoundChannel { sfx, voice, music }

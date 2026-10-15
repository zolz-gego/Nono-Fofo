import '../../sound/domain/sound_event.dart';
import 'character_action.dart';

/// Ready-made reactions: a pose + a sound (with the brother's voice) + how
/// long to hold before going back to idle. Games call `controller.react(...)`
/// instead of wiring poses and sounds every time.
enum CharacterReaction {
  greet(CharacterAction.wave, SoundEvent.charIdleTap, Duration(seconds: 2)),
  correct(CharacterAction.cheer, SoundEvent.correctAnswer, Duration(seconds: 2)),
  wrong(CharacterAction.wrong, SoundEvent.wrongAnswer, Duration(seconds: 2)),
  think(CharacterAction.hint, SoundEvent.hint, Duration(seconds: 3)),
  encourage(CharacterAction.encourage, SoundEvent.tryAgain, Duration(seconds: 2)),
  celebrate(
      CharacterAction.celebrate, SoundEvent.levelComplete, Duration(seconds: 3)),
  surprised(
      CharacterAction.surprised, SoundEvent.charSurprise, Duration(seconds: 2)),
  win(CharacterAction.celebrate, SoundEvent.gameWin, Duration(seconds: 3)),
  lose(CharacterAction.wrong, SoundEvent.gameLose, Duration(seconds: 3)),
  run(CharacterAction.run, SoundEvent.charRun, null),
  sleep(CharacterAction.sleep, SoundEvent.charSleep, null);

  const CharacterReaction(this.action, this.sound, this.hold);

  final CharacterAction action;
  final SoundEvent? sound;

  /// `null` = stay in this pose until told otherwise.
  final Duration? hold;
}

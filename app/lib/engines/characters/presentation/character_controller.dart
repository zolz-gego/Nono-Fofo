import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/domain/character_id.dart';
import '../../sound/application/sound_service.dart';
import '../domain/character_action.dart';
import '../domain/character_reaction.dart';

/// Drives one brother on screen. Create one per character per screen, pass
/// it to `AnimatedCharacter`, then call [react], [play] or [say].
///
/// ```dart
/// final nono = CharacterController(CharacterId.nono, sound: sl());
/// nono.react(CharacterReaction.correct, say: 'برافو!');
/// ```
class CharacterController extends ChangeNotifier {
  CharacterController(
    this.character, {
    this.sound,
    CharacterAction initial = CharacterAction.idle,
  }) : _action = initial;

  final CharacterId character;
  final SoundService? sound;

  CharacterAction _action;
  int _playToken = 0;
  String? _speech;
  Timer? _holdTimer;
  Timer? _speechTimer;
  bool _disposed = false;

  CharacterAction get action => _action;
  String? get speech => _speech;

  /// Changes every time a motion should restart (even for the same action).
  int get playToken => _playToken;

  /// Shows [action]. With [hold], returns to [then] (idle) afterwards.
  void play(
    CharacterAction action, {
    Duration? hold,
    CharacterAction then = CharacterAction.idle,
  }) {
    _holdTimer?.cancel();
    _action = action;
    _playToken++;
    _notify();
    if (hold != null) {
      _holdTimer = Timer(hold, () => play(then));
    }
  }

  /// Pose + sound (+ voice) + optional speech bubble in one call.
  void react(CharacterReaction reaction, {String? say, bool withSound = true}) {
    play(reaction.action, hold: reaction.hold);
    if (withSound && reaction.sound != null) {
      sound?.play(reaction.sound!, by: character);
    }
    if (say != null) this.say(say, duration: reaction.hold);
  }

  void idle() => play(CharacterAction.idle);

  /// Shows a speech bubble above the head.
  void say(String text, {Duration? duration}) {
    _speechTimer?.cancel();
    _speech = text;
    _notify();
    _speechTimer = Timer(
      duration ?? const Duration(milliseconds: 2500),
      hideSpeech,
    );
  }

  void hideSpeech() {
    _speechTimer?.cancel();
    if (_speech == null) return;
    _speech = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _holdTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }
}

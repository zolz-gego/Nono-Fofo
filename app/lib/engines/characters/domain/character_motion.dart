import 'dart:math' as math;

import 'character_action.dart';

/// The procedural motion applied on top of a pose at one instant.
/// Offsets are fractions of the character's drawn height, so motion scales
/// with the character size. Rotation is in radians around the feet.
class MotionFrame {
  const MotionFrame({
    this.dx = 0,
    this.dy = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotation = 0,
  });

  static const identity = MotionFrame();

  final double dx;
  final double dy;
  final double scaleX;
  final double scaleY;
  final double rotation;
}

/// How an action moves: its period and whether it loops. One-shot motions
/// play once, then the character keeps breathing in that pose.
class MotionSpec {
  const MotionSpec(this.period, this.frameAt, {this.loop = true});

  final Duration period;
  final bool loop;

  /// [t] goes 0 -> 1 over [period].
  final MotionFrame Function(double t) frameAt;
}

/// Pure motion definitions shared by the Flutter widget and the Flame
/// component. Tune the feel of every action here.
abstract final class CharacterMotions {
  static const _tau = 2 * math.pi;

  static MotionSpec of(CharacterAction action) => switch (action) {
        CharacterAction.idle => breathe,
        CharacterAction.run => const MotionSpec(
            Duration(milliseconds: 420), _run),
        CharacterAction.cheer => const MotionSpec(
            Duration(milliseconds: 700), _cheer),
        CharacterAction.celebrate => const MotionSpec(
            Duration(milliseconds: 900), _celebrate),
        CharacterAction.wrong => const MotionSpec(
            Duration(milliseconds: 650), _shake,
            loop: false),
        CharacterAction.surprised => const MotionSpec(
            Duration(milliseconds: 500), _pop,
            loop: false),
        CharacterAction.hint => const MotionSpec(
            Duration(milliseconds: 2200), _ponder),
        CharacterAction.encourage => const MotionSpec(
            Duration(milliseconds: 1000), _nod),
        CharacterAction.wave => const MotionSpec(
            Duration(milliseconds: 1100), _rock),
        CharacterAction.write ||
        CharacterAction.read =>
          const MotionSpec(Duration(milliseconds: 2400), _sway),
        CharacterAction.sleep => const MotionSpec(
            Duration(milliseconds: 3400), _sleep),
      };

  /// Gentle breathing, also used after one-shot motions finish.
  static const breathe = MotionSpec(Duration(milliseconds: 2400), _breathe);

  static MotionFrame _breathe(double t) {
    final s = math.sin(t * _tau);
    return MotionFrame(scaleY: 1 + 0.014 * s, scaleX: 1 - 0.006 * s);
  }

  static MotionFrame _run(double t) {
    final bounce = math.sin(t * _tau).abs();
    return MotionFrame(
      dy: -0.035 * bounce,
      scaleY: 1 + 0.02 * bounce,
      rotation: 0.05 + 0.02 * math.sin(t * _tau),
    );
  }

  static MotionFrame _jump(double t, double height) {
    final air = math.sin(t * math.pi);
    final squash = math.pow(1 - air, 4) * 0.07;
    return MotionFrame(dy: -height * air, scaleY: 1 - squash, scaleX: 1 + squash);
  }

  static MotionFrame _cheer(double t) => _jump(t, 0.07);

  static MotionFrame _celebrate(double t) {
    final j = _jump(t, 0.11);
    return MotionFrame(
      dy: j.dy,
      scaleX: j.scaleX,
      scaleY: j.scaleY,
      rotation: 0.06 * math.sin(t * _tau),
    );
  }

  static MotionFrame _shake(double t) => MotionFrame(
        dx: 0.025 * math.sin(t * 3 * _tau) * (1 - t),
        scaleY: 1 - 0.03 * math.sin(t * math.pi),
      );

  static MotionFrame _pop(double t) {
    final p = math.sin(t * math.pi);
    return MotionFrame(dy: -0.04 * p, scaleX: 1 + 0.08 * p, scaleY: 1 + 0.1 * p);
  }

  static MotionFrame _ponder(double t) =>
      MotionFrame(rotation: 0.04 * math.sin(t * _tau));

  static MotionFrame _nod(double t) {
    final s = math.sin(t * _tau);
    return MotionFrame(dy: 0.012 * s, scaleY: 1 - 0.015 * s);
  }

  static MotionFrame _rock(double t) =>
      MotionFrame(rotation: 0.035 * math.sin(t * _tau));

  static MotionFrame _sway(double t) => MotionFrame(
        rotation: 0.015 * math.sin(t * _tau),
        scaleY: 1 + 0.008 * math.sin(t * 2 * _tau),
      );

  static MotionFrame _sleep(double t) {
    final s = math.sin(t * _tau);
    return MotionFrame(scaleY: 1 + 0.03 * s, scaleX: 1 + 0.01 * s);
  }
}

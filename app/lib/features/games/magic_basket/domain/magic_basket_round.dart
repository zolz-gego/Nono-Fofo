import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';
import 'magic_basket_config.dart';

/// What happened to a caught apple.
enum BasketCatch {
  /// One of the letter's sounds: it fills a slot.
  correct,

  /// One of the letter's sounds, but the basket only has room left for the
  /// sounds still missing: no slot, no mistake.
  notNeeded,

  /// Not the letter's sound: a mistake.
  wrong,
}

/// The rules of one Magic basket game, without any drawing: which sounds
/// fall, what counts as a catch or a mistake, and the stars at the end.
///
/// The child must catch [goal] apples with the letter's sounds, and at
/// least one apple of each sound.
class MagicBasketRound extends Equatable {
  const MagicBasketRound._({
    required this.config,
    required this.target,
    required this.sounds,
    required this.distractors,
    this.caught = const [],
    this.wrongCatches = 0,
    this.missed = 0,
  });

  /// [language] picks Arabic or English sounds. Wrong apples carry any
  /// other letter's sound from [pool], except the target's own sounds and
  /// its debatable ones (`neverDrop`).
  factory MagicBasketRound.start({
    required MagicBasketConfig config,
    required CopticLetter target,
    required List<CopticLetter> pool,
    required String language,
  }) {
    final sounds = target.soundsIn(language);
    final banned = {...sounds, ...target.neverDropIn(language)};
    final distractors = <String>{
      for (final letter in pool)
        for (final sound in letter.soundsIn(language))
          if (!banned.contains(sound)) sound,
    }.toList();
    return MagicBasketRound._(
      config: config,
      target: target,
      sounds: sounds,
      distractors: distractors,
    );
  }

  final MagicBasketConfig config;
  final CopticLetter target;

  /// The letter's sounds: each must be caught at least once.
  final List<String> sounds;

  /// Sounds the wrong apples may carry.
  final List<String> distractors;

  /// Sounds caught so far, in catch order (one per filled slot).
  final List<String> caught;
  final int wrongCatches;

  /// Right apples that hit the ground.
  final int missed;

  int get goal => max(config.catchesToWin, sounds.length);
  bool get isFinished => caught.length >= goal;
  int get mistakes => wrongCatches + (config.countMissedAsMistake ? missed : 0);
  int get stars => config.starsFor(mistakes);

  bool isRight(String sound) => sounds.contains(sound);
  bool hasCaught(String sound) => caught.contains(sound);

  /// Sounds of the letter not caught yet.
  List<String> get stillMissing =>
      sounds.where((s) => !caught.contains(s)).toList();

  /// The slots left are all needed for the missing sounds.
  bool get onlyMissingFit => goal - caught.length <= stillMissing.length;

  /// Whether a right apple with [sound] would still fill a slot.
  bool isNeeded(String sound) =>
      isRight(sound) && (!onlyMissingFit || !hasCaught(sound));

  /// The sound for the next apple. [rightShowing] is how many needed apples
  /// are falling now: when none is, a right one is more likely.
  String nextSound(Random random, {required int rightShowing, bool? right}) {
    final chance = rightShowing == 0
        ? max(config.targetChance, 0.55)
        : config.targetChance;
    final pickRight =
        right ?? (distractors.isEmpty || random.nextDouble() < chance);
    if (!pickRight) return distractors[random.nextInt(distractors.length)];
    // Missing sounds first, so every sound shows up.
    final missing = stillMissing;
    if (missing.isNotEmpty && (onlyMissingFit || random.nextDouble() < 0.6)) {
      return missing[random.nextInt(missing.length)];
    }
    return sounds[random.nextInt(sounds.length)];
  }

  BasketCatch judge(String sound) => !isRight(sound)
      ? BasketCatch.wrong
      : isNeeded(sound)
      ? BasketCatch.correct
      : BasketCatch.notNeeded;

  /// The basket caught an apple with [sound].
  MagicBasketRound pick(String sound) {
    if (isFinished) return this;
    return switch (judge(sound)) {
      BasketCatch.correct => _copy(caught: [...caught, sound]),
      BasketCatch.notNeeded => this,
      BasketCatch.wrong => _copy(wrongCatches: wrongCatches + 1),
    };
  }

  /// An apple the child still needed hit the ground.
  MagicBasketRound miss() => isFinished ? this : _copy(missed: missed + 1);

  MagicBasketRound _copy({
    List<String>? caught,
    int? wrongCatches,
    int? missed,
  }) => MagicBasketRound._(
    config: config,
    target: target,
    sounds: sounds,
    distractors: distractors,
    caught: caught ?? this.caught,
    wrongCatches: wrongCatches ?? this.wrongCatches,
    missed: missed ?? this.missed,
  );

  @override
  List<Object?> get props => [target, sounds, caught, wrongCatches, missed];
}

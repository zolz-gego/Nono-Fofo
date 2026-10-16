import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';
import 'letter_hunt_rules.dart';

/// The rules of one "find the letter" game, without any drawing: which
/// letters appear, what counts as a catch or a mistake, and the stars at the
/// end. [C] is the game's own config (fish speeds, balloon colors…).
class LetterHuntRound<C extends LetterHuntRules> extends Equatable {
  const LetterHuntRound._({
    required this.config,
    required this.target,
    required this.letters,
    this.caught = 0,
    this.wrongCatches = 0,
    this.missed = 0,
  });

  /// Picks the letters for this game: the target plus random others, up to
  /// `config.maxDifferentLetters` in total.
  factory LetterHuntRound.start({
    required C config,
    required CopticLetter target,
    required List<CopticLetter> pool,
    Random? random,
  }) {
    final others = pool.where((l) => l != target).toList()..shuffle(random);
    final count = max(1, config.maxDifferentLetters - 1);
    return LetterHuntRound._(
      config: config,
      target: target,
      letters: [target, ...others.take(count)],
    );
  }

  final C config;
  final CopticLetter target;

  /// Every letter that may appear (target first).
  final List<CopticLetter> letters;

  final int caught;
  final int wrongCatches;

  /// Targets that got away without being caught.
  final int missed;

  int get goal => config.catchesToWin;
  bool get isFinished => caught >= goal;
  int get mistakes => wrongCatches + (config.countMissedAsMistake ? missed : 0);
  int get stars => config.starsFor(mistakes);

  List<CopticLetter> get distractors => letters.sublist(1);

  bool isTarget(CopticLetter letter) => letter == target;

  /// The letter for the next item. [targetsShowing] is how many targets are
  /// on screen now: when none is, a target is more likely, so the child
  /// never waits long.
  CopticLetter nextLetter(Random random, {required int targetsShowing}) {
    if (distractors.isEmpty) return target;
    final chance = targetsShowing == 0
        ? max(config.targetChance, 0.5)
        : config.targetChance;
    if (random.nextDouble() < chance) return target;
    return distractors[random.nextInt(distractors.length)];
  }

  /// Any letter except the target (or the target if there is no other).
  CopticLetter randomDistractor(Random random) => distractors.isEmpty
      ? target
      : distractors[random.nextInt(distractors.length)];

  /// The child caught an item carrying [letter].
  LetterHuntRound<C> pick(CopticLetter letter) => isFinished
      ? this
      : isTarget(letter)
      ? _copy(caught: caught + 1)
      : _copy(wrongCatches: wrongCatches + 1);

  /// An item carrying the target left the screen.
  LetterHuntRound<C> missTarget() =>
      isFinished ? this : _copy(missed: missed + 1);

  LetterHuntRound<C> _copy({int? caught, int? wrongCatches, int? missed}) =>
      LetterHuntRound._(
        config: config,
        target: target,
        letters: letters,
        caught: caught ?? this.caught,
        wrongCatches: wrongCatches ?? this.wrongCatches,
        missed: missed ?? this.missed,
      );

  @override
  List<Object?> get props => [target, letters, caught, wrongCatches, missed];
}

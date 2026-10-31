import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';
import '../../letter_puzzle/domain/letter_puzzle_config.dart';
import '../../letter_puzzle/presentation/letter_puzzle_cubit.dart';

/// Which choice a word is on: the missing Coptic letter, then what it
/// sounds like in the word, then done.
enum GapStep { letter, sound, done }

/// How an option button looks: still in play, picked wrong (red, out), or
/// taken away by a hint.
enum OptionMark { none, wrong, hidden }

/// One word with a gap: its Coptic [letters], the [gap] index, the
/// [letterOptions] for the gap (one is right) and then the [soundOptions]
/// for what the missing letter sounds like in the word (one is [sound]).
/// [marks] are the current step's options (wrong picks, hidden by a hint).
class GapQuestion extends Equatable {
  const GapQuestion({
    required this.letters,
    required this.gap,
    required this.letterOptions,
    required this.sound,
    required this.soundOptions,
    this.step = GapStep.letter,
    this.marks = const [],
  });

  final List<CopticLetter> letters;
  final int gap;
  final List<CopticLetter> letterOptions;

  /// What the missing letter sounds like in this word.
  final String sound;
  final List<String> soundOptions;
  final GapStep step;
  final List<OptionMark> marks;

  CopticLetter get answer => letters[gap];
  bool get done => step == GapStep.done;

  /// How many options the current step has.
  int get optionCount => switch (step) {
    GapStep.letter => letterOptions.length,
    GapStep.sound => soundOptions.length,
    GapStep.done => 0,
  };

  OptionMark markAt(int i) => i < marks.length ? marks[i] : OptionMark.none;

  bool _rightAt(int i) => switch (step) {
    GapStep.letter => letterOptions[i] == answer,
    GapStep.sound => soundOptions[i] == sound,
    GapStep.done => false,
  };

  /// Wrong options a hint can still take away.
  List<int> get _hideable => [
    for (var i = 0; i < optionCount; i++)
      if (!_rightAt(i) && markAt(i) == OptionMark.none) i,
  ];

  bool get canHint => !done && _hideable.isNotEmpty;

  /// Picks option [i]: right moves to the next step, wrong marks it red.
  /// Null when it can't be picked.
  ({GapQuestion question, bool right})? pick(int i) {
    if (done || i < 0 || i >= optionCount || markAt(i) != OptionMark.none) {
      return null;
    }
    if (_rightAt(i)) {
      return (
        question: _with(
          step: step == GapStep.letter ? GapStep.sound : GapStep.done,
          marks: const [],
        ),
        right: true,
      );
    }
    return (question: _mark(i, OptionMark.wrong), right: false);
  }

  /// Takes one wrong option away. Null when none is left.
  GapQuestion? hint(Random random) {
    final hideable = _hideable;
    if (done || hideable.isEmpty) return null;
    return _mark(hideable[random.nextInt(hideable.length)], OptionMark.hidden);
  }

  GapQuestion _mark(int i, OptionMark mark) => _with(
    marks: [for (var j = 0; j < optionCount; j++) j == i ? mark : markAt(j)],
  );

  GapQuestion _with({GapStep? step, List<OptionMark>? marks}) => GapQuestion(
    letters: letters,
    gap: gap,
    letterOptions: letterOptions,
    sound: sound,
    soundOptions: soundOptions,
    step: step ?? this.step,
    marks: marks ?? this.marks,
  );

  @override
  List<Object?> get props => [
    letters,
    gap,
    letterOptions,
    sound,
    soundOptions,
    step,
    marks,
  ];
}

/// Makes the questions for one language. Wrong options never also fit:
/// a wrong letter never makes the gap's sound (in letters.json or in any
/// word of the list), and a wrong sound is never one the missing letter
/// makes.
class GapMaker {
  GapMaker({
    required List<CopticLetter> alphabet,
    required Iterable<PuzzleWord> words,
    required String languageCode,
    this.options = 3,
  }) : _alphabet = alphabet {
    for (final l in alphabet) {
      _soundsOf.putIfAbsent(l.id, () => {}).addAll(l.soundsIn(languageCode));
    }
    for (final w in words) {
      if (w.sounds.length != w.letters.length) continue;
      for (final (i, id) in w.letters.indexed) {
        _soundsOf.putIfAbsent(id, () => {}).add(w.sounds[i]);
        _soundPool.add(w.sounds[i]);
      }
    }
  }

  final List<CopticLetter> _alphabet;

  /// Options per step (the right one included).
  final int options;

  /// Every sound each letter makes in this language.
  final Map<String, Set<String>> _soundsOf = {};

  /// Every sound the words use, for the wrong sound options.
  final Set<String> _soundPool = {};

  /// A question for [item] with the gap at a random letter.
  GapQuestion make(PuzzleItem item, Random random) {
    final gap = random.nextInt(item.letters.length);
    final answer = item.letters[gap];
    final sound = item.word.sounds[gap];
    final wrongLetters = [
      for (final l in _alphabet)
        if (l.id != answer.id &&
            l.small != answer.small &&
            !(_soundsOf[l.id]?.contains(sound) ?? false))
          l,
    ]..shuffle(random);
    final mine = _soundsOf[answer.id] ?? const {};
    final wrongSounds = [
      for (final s in _soundPool)
        if (s != sound && !mine.contains(s)) s,
    ]..shuffle(random);
    return GapQuestion(
      letters: item.letters,
      gap: gap,
      letterOptions: [answer, ...wrongLetters.take(options - 1)]
        ..shuffle(random),
      sound: sound,
      soundOptions: [sound, ...wrongSounds.take(options - 1)]..shuffle(random),
    );
  }
}

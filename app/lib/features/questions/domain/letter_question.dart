import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../letters/domain/coptic_letter.dart';
import 'question.dart';

/// Which side of a letter question is shown, and which is picked.
enum LetterSide { letter, name }

/// Which form a shown (or offered) letter takes.
enum LetterForm { capital, small, mixed }

/// A recipe for multiple-choice letter questions, from
/// `assets/content/questions/letter_mcq.json`. The real question is made
/// fresh each time from a level's letters ([LetterQuestion.make]).
class LetterQuestionTemplate extends Question {
  const LetterQuestionTemplate({
    required super.id,
    required this.level,
    required this.show,
    this.form = LetterForm.mixed,
    this.choices = 3,
  }) : super(type: typeId);

  factory LetterQuestionTemplate.fromJson(Map<String, dynamic> json) =>
      LetterQuestionTemplate(
        id: json['id'] as String,
        level: (json['level'] as num).toInt(),
        show: LetterSide.values.byName(json['show'] as String),
        form: LetterForm.values.byName(json['form'] as String? ?? 'mixed'),
        choices: (json['choices'] as num?)?.toInt() ?? 3,
      );

  static const String typeId = 'letter_mcq';

  /// The level whose letters it asks about.
  final int level;

  /// What the question shows: the letter (pick its name) or the name (pick
  /// the letter).
  final LetterSide show;
  final LetterForm form;

  /// How many answers to pick from (the right one included).
  final int choices;

  @override
  List<Object?> get props => [...super.props, level, show, form, choices];
}

/// One multiple-choice letter question, ready to ask.
class LetterQuestion extends Equatable {
  const LetterQuestion({
    required this.show,
    required this.answer,
    required this.choices,
    required this.capital,
  });

  /// A random question from [templates] about one of [pool], with wrong
  /// answers from the rest of [pool]. Avoids the letters in [avoid] (the
  /// last ones asked) while there are others to ask.
  factory LetterQuestion.make({
    required List<LetterQuestionTemplate> templates,
    required List<CopticLetter> pool,
    Random? random,
    Iterable<String> avoid = const [],
  }) {
    final r = random ?? Random();
    final t = templates[r.nextInt(templates.length)];
    final fresh = pool.where((l) => !avoid.contains(l.id)).toList();
    final from = fresh.isEmpty ? pool : fresh;
    final answer = from[r.nextInt(from.length)];
    final others = [...pool.where((l) => l.id != answer.id)]..shuffle(r);
    final choices = [
      answer,
      ...others.take(max(0, min(t.choices, pool.length) - 1)),
    ]..shuffle(r);
    return LetterQuestion(
      show: t.show,
      answer: answer,
      choices: choices,
      capital: switch (t.form) {
        LetterForm.capital => true,
        LetterForm.small => false,
        LetterForm.mixed => r.nextBool(),
      },
    );
  }

  final LetterSide show;
  final CopticLetter answer;

  /// Every answer offered, in the order shown; [answer] is one of them.
  final List<CopticLetter> choices;

  /// Letters are shown in capital form (else small).
  final bool capital;

  int get answerIndex => choices.indexOf(answer);

  /// [letter] as drawn (Avva Shenouda keys).
  String glyph(CopticLetter letter) => capital ? letter.capital : letter.small;

  @override
  List<Object?> get props => [show, answer, choices, capital];
}

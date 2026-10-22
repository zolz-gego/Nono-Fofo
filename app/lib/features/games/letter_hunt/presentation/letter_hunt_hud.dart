import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shell/presentation/game_question_bar.dart';
import '../../shell/presentation/question_bar_layout.dart';
import '../domain/letter_hunt_rules.dart';
import 'letter_hunt_cubit.dart';

/// The question bar of a "find the letter" game: [icon] with the items
/// caught out of the goal, and [label] + the letter to catch.
class LetterHuntHud extends StatelessWidget {
  const LetterHuntHud({
    super.key,
    required this.layout,
    required this.cubit,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final QuestionBarLayout layout;
  final LetterHuntCubit<LetterHuntRules> cubit;
  final String label;
  final FaIconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        LetterHuntCubit<LetterHuntRules>,
        LetterHuntState<LetterHuntRules>
      >(
        bloc: cubit,
        builder: (context, state) => GameQuestionBar(
          layout: layout,
          label: label,
          letter: state.round.target,
          icon: icon,
          iconColor: iconColor,
          caught: state.landed,
          goal: state.round.goal,
          // A wrong catch or a missed item gives the letter a shake.
          shakeKey: state.eventId,
          shake:
              state.event == LetterHuntEvent.wrong ||
              state.event == LetterHuntEvent.missed,
        ),
      );
}

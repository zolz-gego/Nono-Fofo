import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../shell/presentation/game_question_bar.dart';
import '../game/magic_basket_layout.dart';
import 'magic_basket_cubit.dart';

/// The question bar of the Magic basket: the apples caught out of the goal,
/// one chip per sound of the letter (a "?" until caught), and the letter.
class MagicBasketHud extends StatelessWidget {
  const MagicBasketHud({super.key, required this.layout, required this.cubit});

  final MagicBasketLayout layout;
  final MagicBasketCubit cubit;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MagicBasketCubit, MagicBasketState>(
        bloc: cubit,
        builder: (context, state) {
          final round = state.round;
          return GameQuestionBar(
            layout: layout,
            label: context.l10n.magicBasketSounds,
            letter: round.target,
            icon: AppIcons.apple,
            iconColor: AppColors.apple,
            caught: state.landed,
            goal: round.goal,
            chips: [
              for (final s in round.sounds)
                QuestionBarChip(text: s, found: round.hasCaught(s)),
            ],
            // A wrong catch or a fallen apple gives the letter a shake.
            shakeKey: state.eventId,
            shake:
                state.event == BasketEvent.wrong ||
                state.event == BasketEvent.missed,
          );
        },
      );
}

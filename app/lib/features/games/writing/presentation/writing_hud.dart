import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../domain/letter_strokes.dart';
import 'writing_cubit.dart';

/// Top card: which board (small / capital), how much of the letter is
/// coloured (a chalk stick), the mess meter and the wipes left.
class WritingHud extends StatelessWidget {
  const WritingHud({
    super.key,
    required this.letter,
    required this.state,
    required this.passAt,
    required this.warnAt,
    required this.wipesToFail,
  });

  final CopticLetter letter;
  final WritingState state;
  final double passAt;
  final double warnAt;
  final int wipesToFail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done =
        state.phase == WritingPhase.boardPassed ||
        state.phase == WritingPhase.passed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMd,
        vertical: AppDimens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.speechBubbleBorder, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final form in LetterForm.values)
            _FormChip(
              glyph: form == LetterForm.small ? letter.small : letter.capital,
              label: form == LetterForm.small
                  ? l10n.writingSmall
                  : l10n.writingCapital,
              active: state.form == form,
              done:
                  form.index < state.form.index || (form == state.form && done),
            ),
          const SizedBox(width: AppDimens.spaceMd),
          _Meter(
            icon: AppIcons.chalkFilled,
            label: l10n.writingFilled,
            value: (state.filled / passAt).clamp(0, 1),
            fill: done ? AppColors.correct : AppColors.chalk.first,
            track: AppColors.board,
            width: 180,
          ),
          const SizedBox(width: AppDimens.spaceMd),
          _Meter(
            icon: AppIcons.sponge,
            label: l10n.writingMess,
            value: state.mess,
            fill: state.mess >= warnAt ? AppColors.coral : AppColors.sunYellow,
            track: AppColors.sand,
            width: 110,
            mark: warnAt,
          ),
          const SizedBox(width: AppDimens.spaceSm),
          Tooltip(
            message: l10n.writingWipesLeft,
            child: Row(
              children: [
                for (var i = 0; i < wipesToFail; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FaIcon(
                      AppIcons.sponge,
                      size: 18,
                      color: i < wipesToFail - state.wipes
                          ? AppColors.sponge
                          : AppColors.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormChip extends StatelessWidget {
  const _FormChip({
    required this.glyph,
    required this.label,
    required this.active,
    required this.done,
  });

  final String glyph;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimens.normal,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
      decoration: BoxDecoration(
        color: active ? AppColors.board : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: AppTextStyles.coptic(AppTextVariant.h2).copyWith(
              color: active ? AppColors.chalk.first : AppColors.coptic,
              height: 1.2,
            ),
          ),
          const SizedBox(width: AppDimens.spaceXs),
          if (done)
            const FaIcon(AppIcons.passed, size: 16, color: AppColors.correct)
          else
            AppText(
              label,
              variant: AppTextVariant.caption,
              color: active ? AppColors.textOnDark : AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.icon,
    required this.label,
    required this.value,
    required this.fill,
    required this.track,
    required this.width,
    this.mark,
  });

  final FaIconData icon;
  final String label;
  final double value;
  final Color fill;
  final Color track;
  final double width;

  /// A small tick on the bar (e.g. where the warning comes).
  final double? mark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Row(
        children: [
          FaIcon(icon, size: 18, color: AppColors.cocoa),
          const SizedBox(width: AppDimens.spaceXs),
          SizedBox(
            width: width,
            height: 18,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.cocoa, width: 1.5),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: value),
                        duration: AppDimens.fast,
                        builder: (context, v, _) => FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (mark != null)
                  Align(
                    alignment: AlignmentDirectional(mark! * 2 - 1, 0),
                    child: Container(
                      width: 2,
                      height: 18,
                      color: AppColors.cocoa,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

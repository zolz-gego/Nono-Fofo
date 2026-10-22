import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../letters/domain/coptic_letter.dart';
import 'question_bar_layout.dart';

/// The question bar at the top of a game, in two compact rows. Beside the
/// settings button: [icon] with [caught] out of [goal], then any [chips].
/// Under it, in one line: [label], the [letter] (capital and small) and its
/// name. Positions come from [layout].
///
/// Give [shakeKey] a new value (an event id) with [shake] true to shake
/// the letter after a wrong pick.
class GameQuestionBar extends StatelessWidget {
  const GameQuestionBar({
    super.key,
    required this.layout,
    required this.label,
    required this.letter,
    required this.icon,
    required this.iconColor,
    required this.caught,
    required this.goal,
    this.chips = const [],
    this.shakeKey,
    this.shake = false,
  });

  final QuestionBarLayout layout;
  final String label;
  final CopticLetter letter;
  final FaIconData icon;
  final Color iconColor;
  final int caught;
  final int goal;
  final List<QuestionBarChip> chips;
  final Object? shakeKey;
  final bool shake;

  @override
  Widget build(BuildContext context) {
    final l = layout;
    final lang = Localizations.localeOf(context).languageCode;
    final chip = l.progressHeight * 0.78;

    return Positioned(
      left: l.progressLeft,
      top: l.hudTop,
      width: l.progressWidth,
      height: l.cardBottom - l.hudTop,
      child: IgnorePointer(
        child: Column(
          children: [
            SizedBox(
              height: l.progressHeight,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Pill(
                        height: chip,
                        child: _Count(
                          icon: icon,
                          color: iconColor,
                          caught: caught,
                          goal: goal,
                          size: chip,
                        ),
                      ),
                      for (final c in chips) ...[
                        const SizedBox(width: AppDimens.spaceSm),
                        _Chip(chip: c, arabic: lang == 'ar', size: chip),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: l.nameTop - l.hudTop - l.progressHeight),
            SizedBox(
              height: l.nameHeight,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _Pill(
                    height: l.nameHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          label,
                          variant: AppTextVariant.h3,
                          color: AppColors.textHeading,
                        ),
                        const SizedBox(width: AppDimens.spaceSm),
                        Text(
                              '${letter.capital}${letter.small}',
                              // Coptic keys must not be mirrored in Arabic.
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.coptic(AppTextVariant.h1)
                                  .copyWith(
                                    fontSize: l.nameHeight * 0.8,
                                    height: 1.1,
                                  ),
                            )
                            .animate(
                              key: ValueKey(shakeKey),
                              target: shake ? 1 : 0,
                            )
                            .shake(hz: 5, offset: const Offset(6, 0)),
                        const SizedBox(width: AppDimens.spaceSm),
                        AppText(
                          letter.nameIn(lang),
                          variant: AppTextVariant.h3,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing to find, shown after the count on the [GameQuestionBar]: a
/// grey "?" until [found], then [text] with a check.
class QuestionBarChip {
  const QuestionBarChip({required this.text, required this.found});

  final String text;
  final bool found;
}

/// A light rounded box behind a group on the bar, so it reads over any
/// scene.
class _Pill extends StatelessWidget {
  const _Pill({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: EdgeInsets.symmetric(horizontal: height * 0.35),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(height / 2),
      border: Border.all(color: AppColors.speechBubbleBorder, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: child,
  );
}

/// "🍎 3/5": the items caught out of the goal. Pops on each catch.
class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.color,
    required this.caught,
    required this.goal,
    required this.size,
  });

  final FaIconData icon;
  final Color color;
  final int caught;
  final int goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: size * 0.5, color: color),
            SizedBox(width: size * 0.18),
            Text(
              '$caught/$goal',
              // Numbers read left to right in both languages.
              textDirection: TextDirection.ltr,
              style: AppTextStyles.english(AppTextVariant.h3).copyWith(
                fontSize: size * 0.5,
                height: 1.1,
                color: AppColors.textHeading,
              ),
            ),
          ],
        )
        .animate(key: ValueKey(caught))
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: AppDimens.slow,
        );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.chip, required this.arabic, required this.size});

  final QuestionBarChip chip;
  final bool arabic;
  final double size;

  @override
  Widget build(BuildContext context) {
    final found = chip.found;
    final style =
        (arabic
                ? AppTextStyles.arabic(AppTextVariant.h3)
                : AppTextStyles.english(AppTextVariant.h3))
            .copyWith(
              fontSize: size * 0.55,
              height: 1.1,
              color: found ? AppColors.white : AppColors.textBody,
            );
    final box = AnimatedContainer(
      duration: AppDimens.normal,
      height: size,
      constraints: BoxConstraints(minWidth: size * 1.4),
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: found
            ? AppColors.correct
            : AppColors.mistBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: found
              ? AppColors.cocoa
              : AppColors.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hidden until found: the bar must not give the answer away.
          if (found)
            Text(chip.text, style: style)
          else
            FaIcon(
              AppIcons.hiddenSound,
              size: size * 0.42,
              color: AppColors.outline,
            ),
          if (found) ...[
            SizedBox(width: size * 0.15),
            FaIcon(AppIcons.check, size: size * 0.42, color: AppColors.white),
          ],
        ],
      ),
    );
    if (!found) return box;
    return box.animate().scale(
      begin: const Offset(1.3, 1.3),
      curve: Curves.elasticOut,
      duration: AppDimens.slow,
    );
  }
}

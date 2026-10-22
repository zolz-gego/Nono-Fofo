import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../game/magic_basket_layout.dart';
import 'magic_basket_cubit.dart';

/// The top of the scene, in two compact rows. Beside the settings button:
/// the apples caught out of the goal and one chip per sound of the letter
/// (a "?" until caught). Under it, in one line: [label], the letter
/// (capital and small) and its name. Positions come from [layout].
class MagicBasketHud extends StatelessWidget {
  const MagicBasketHud({
    super.key,
    required this.layout,
    required this.cubit,
    required this.label,
  });

  final MagicBasketLayout layout;
  final MagicBasketCubit cubit;
  final String label;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MagicBasketCubit, MagicBasketState>(
        bloc: cubit,
        builder: _rows,
      );

  Widget _rows(BuildContext context, MagicBasketState state) {
    final round = state.round;
    final l = layout;
    final lang = Localizations.localeOf(context).languageCode;
    final arabic = lang == 'ar';
    final chip = l.progressHeight * 0.78;

    // A wrong catch or a fallen apple gives the letter a little shake.
    final shake =
        state.event == BasketEvent.wrong || state.event == BasketEvent.missed;

    return Positioned(
      left: l.progressLeft,
      top: l.hudTop,
      width: l.progressWidth,
      height: l.cardBottom - l.hudTop,
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
                        caught: state.landed,
                        goal: round.goal,
                        size: chip,
                      ),
                    ),
                    for (final s in round.sounds) ...[
                      const SizedBox(width: AppDimens.spaceSm),
                      _SoundChip(
                        sound: s,
                        arabic: arabic,
                        caught: round.hasCaught(s),
                        size: chip,
                      ),
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
                            '${round.target.capital}${round.target.small}',
                            // Coptic keys must not be mirrored in Arabic.
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.coptic(AppTextVariant.h1)
                                .copyWith(
                                  fontSize: l.nameHeight * 0.8,
                                  height: 1.1,
                                ),
                          )
                          .animate(
                            key: ValueKey(state.eventId),
                            target: shake ? 1 : 0,
                          )
                          .shake(hz: 5, offset: const Offset(6, 0)),
                      const SizedBox(width: AppDimens.spaceSm),
                      AppText(
                        round.target.nameIn(lang),
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
    );
  }
}

/// A light rounded box behind a group on the top rows, so they read over
/// the sky and the leaves.
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

/// "🍎 3/5": the apples in the basket out of the goal. Pops on each catch.
class _Count extends StatelessWidget {
  const _Count({required this.caught, required this.goal, required this.size});

  final int caught;
  final int goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(AppIcons.apple, size: size * 0.5, color: AppColors.apple),
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

/// One sound of the letter: a grey "?" until an apple with it is caught,
/// then the sound itself.
class _SoundChip extends StatelessWidget {
  const _SoundChip({
    required this.sound,
    required this.arabic,
    required this.caught,
    required this.size,
  });

  final String sound;
  final bool arabic;
  final bool caught;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style =
        (arabic
                ? AppTextStyles.arabic(AppTextVariant.h3)
                : AppTextStyles.english(AppTextVariant.h3))
            .copyWith(
              fontSize: size * 0.55,
              height: 1.1,
              color: caught ? AppColors.white : AppColors.textBody,
            );
    final chip = AnimatedContainer(
      duration: AppDimens.normal,
      height: size,
      constraints: BoxConstraints(minWidth: size * 1.4),
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: caught
            ? AppColors.correct
            : AppColors.mistBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: caught
              ? AppColors.cocoa
              : AppColors.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hidden until caught: the card must not give the answer away.
          if (caught)
            Text(sound, style: style)
          else
            FaIcon(
              AppIcons.hiddenSound,
              size: size * 0.42,
              color: AppColors.outline,
            ),
          if (caught) ...[
            SizedBox(width: size * 0.15),
            FaIcon(AppIcons.check, size: size * 0.42, color: AppColors.white),
          ],
        ],
      ),
    );
    if (!caught) return chip;
    return chip.animate().scale(
      begin: const Offset(1.3, 1.3),
      curve: Curves.elasticOut,
      duration: AppDimens.slow,
    );
  }
}

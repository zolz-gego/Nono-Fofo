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

/// The card at the top: [label] + the letter (capital and small) and its
/// name, one chip per sound of the letter (a "?" until caught), and one
/// apple slot per apple to win. Positions come from [layout].
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
        builder: _card,
      );

  Widget _card(BuildContext context, MagicBasketState state) {
    final round = state.round;
    final l = layout;
    final lang = Localizations.localeOf(context).languageCode;
    final arabic = lang == 'ar';

    // A wrong catch or a fallen apple gives the letter a little shake.
    final shake =
        state.event == BasketEvent.wrong || state.event == BasketEvent.missed;

    return Positioned(
      top: l.cardTop,
      left: (l.width - l.cardWidth) / 2,
      width: l.cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.speechBubbleBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: l.chipsTop - l.cardTop,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.h3(label),
                    const SizedBox(width: AppDimens.spaceSm),
                    Text(
                          '${round.target.capital}${round.target.small}',
                          // Coptic keys must not be mirrored in Arabic.
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.coptic(
                            AppTextVariant.h1,
                          ).copyWith(fontSize: l.cardLetterSize, height: 1.1),
                        )
                        .animate(
                          key: ValueKey(state.eventId),
                          target: shake ? 1 : 0,
                        )
                        .shake(hz: 5, offset: const Offset(6, 0)),
                    const SizedBox(width: AppDimens.spaceSm),
                    AppText(
                      round.target.nameIn(lang),
                      variant: AppTextVariant.caption,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: l.chipSize,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, s) in round.sounds.indexed) ...[
                      if (i > 0) const SizedBox(width: AppDimens.spaceSm),
                      _SoundChip(
                        sound: s,
                        arabic: arabic,
                        caught: round.hasCaught(s),
                        size: l.chipSize,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: l.slotsTop - l.chipsTop - l.chipSize),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < round.goal; i++) ...[
                  if (i > 0) SizedBox(width: l.slotGap),
                  _Slot(size: l.slotSize, filled: i < state.landed),
                ],
              ],
            ),
            SizedBox(height: l.cardBottomPadding),
          ],
        ),
      ),
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

class _Slot extends StatelessWidget {
  const _Slot({required this.size, required this.filled});

  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final slot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? AppColors.sunYellow
            : AppColors.mistBlue.withValues(alpha: 0.5),
        border: Border.all(
          color: filled
              ? AppColors.cocoa
              : AppColors.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: FaIcon(
        AppIcons.apple,
        size: size * 0.5,
        color: filled
            ? AppColors.apple
            : AppColors.outline.withValues(alpha: 0.45),
      ),
    );
    if (!filled) return slot;
    return slot.animate().scale(
      begin: const Offset(1.5, 1.5),
      curve: Curves.elasticOut,
      duration: AppDimens.slow,
    );
  }
}

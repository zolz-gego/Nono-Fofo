import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../game/fishing_layout.dart';
import 'fishing_cubit.dart';

/// The card at the top: the letter to catch, and the basket with one slot
/// per fish to win. Slot positions come from [FishingLayout] so caught fish
/// fly exactly into them.
class FishingHud extends StatelessWidget {
  const FishingHud({super.key, required this.layout});

  final FishingLayout layout;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FishingCubit>().state;
    final round = state.round;
    final l = layout;
    final width = l.cardWidth;
    final lang = Localizations.localeOf(context).languageCode;

    // A wrong catch or a missed fish gives the card a little shake.
    final shake =
        state.event == FishingEvent.wrong || state.event == FishingEvent.missed;

    return Positioned(
      top: l.cardTop,
      left: (l.width - width) / 2,
      width: width,
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
              height: l.slotsTop - l.cardTop,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText.h3(context.l10n.catchLetter),
                  const SizedBox(width: AppDimens.spaceSm),
                  Text(
                        round.target.small,
                        style: AppTextStyles.coptic(AppTextVariant.h1)
                            .copyWith(fontSize: l.cardLetterSize, height: 1.1),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < round.goal; i++) ...[
                  if (i > 0) SizedBox(width: l.slotGap),
                  _Slot(size: l.slotSize, filled: i < state.basket),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.spaceSm + 2),
          ],
        ),
      ),
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
        AppIcons.fishing,
        size: size * 0.5,
        color: filled
            ? AppColors.white
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

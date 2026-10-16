import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// The wooden ledge under the board: pick a chalk colour and thickness.
class ChalkTray extends StatelessWidget {
  const ChalkTray({
    super.key,
    required this.colorIndex,
    required this.sizeIndex,
    required this.sizes,
    required this.onColor,
    required this.onSize,
  });

  final int colorIndex;
  final int sizeIndex;

  /// Chalk radii (board units), thin to thick.
  final List<double> sizes;
  final ValueChanged<int> onColor;
  final ValueChanged<int> onSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizeNames = [l10n.writingThin, l10n.writingMedium, l10n.writingThick];
    final chalk = AppColors.chalk[colorIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.boardFrame,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.boardFrameDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < AppColors.chalk.length; i++)
              _ChalkStick(
                color: AppColors.chalk[i],
                selected: i == colorIndex,
                onTap: () => onColor(i),
              ),
            Container(
              width: 2,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
              color: AppColors.boardFrameDark,
            ),
            for (var i = 0; i < sizes.length; i++)
              Tooltip(
                message: i < sizeNames.length ? sizeNames[i] : '',
                child: _SizeDot(
                  diameter: 8 + i * 8,
                  color: chalk,
                  selected: i == sizeIndex,
                  onTap: () => onSize(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChalkStick extends StatelessWidget {
  const _ChalkStick({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 56,
          child: Center(
            child: AnimatedContainer(
              duration: AppDimens.fast,
              transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
              width: 38,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? AppColors.sunYellow
                      : AppColors.boardFrameDark,
                  width: selected ? 3 : 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeDot extends StatelessWidget {
  const _SizeDot({
    required this.diameter,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double diameter;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 48,
          height: 56,
          child: Center(
            child: AnimatedContainer(
              duration: AppDimens.fast,
              width: diameter + 10,
              height: diameter + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.boardDark : AppColors.transparent,
                border: Border.all(
                  color: selected ? AppColors.sunYellow : AppColors.transparent,
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

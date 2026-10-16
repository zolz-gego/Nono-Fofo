import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';

/// The wooden ledge under the board: pick a chalk colour (two rows of
/// sticks), the eraser, and the thickness. [vertical] packs it into a
/// square (thickness and eraser on top, the colours in a grid below), for
/// small screens.
class ChalkTray extends StatelessWidget {
  const ChalkTray({
    super.key,
    required this.colorIndex,
    required this.sizeIndex,
    required this.sizes,
    required this.erasing,
    required this.onColor,
    required this.onSize,
    required this.onEraser,
    this.vertical = false,
  });

  final int colorIndex;
  final int sizeIndex;

  /// Chalk radii (board units), thin to thick.
  final List<double> sizes;

  /// The eraser is in hand (instead of chalk).
  final bool erasing;
  final ValueChanged<int> onColor;
  final ValueChanged<int> onSize;
  final VoidCallback onEraser;
  final bool vertical;

  static const int _perRow = 8;
  static const int _perRowVertical = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizeNames = [l10n.writingThin, l10n.writingMedium, l10n.writingThick];
    final colors = AppColors.chalk;
    final dot = erasing ? AppColors.white : colors[colorIndex];
    final perRow = vertical ? _perRowVertical : _perRow;
    Widget row(int from) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = from; i < colors.length && i < from + perRow; i++)
          _ChalkStick(
            color: colors[i],
            selected: !erasing && i == colorIndex,
            onTap: () => onColor(i),
          ),
      ],
    );
    final sticks = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var from = 0; from < colors.length; from += perRow) row(from),
      ],
    );
    final eraser = Tooltip(
      message: l10n.writingEraser,
      child: _EraserButton(selected: erasing, onTap: onEraser),
    );
    final sizeDots = [
      for (var i = 0; i < sizes.length; i++)
        Tooltip(
          message: i < sizeNames.length ? sizeNames[i] : '',
          child: _SizeDot(
            diameter: 8 + i * 8,
            color: dot,
            selected: i == sizeIndex,
            onTap: () => onSize(i),
          ),
        ),
    ];
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceSm,
          vertical: AppDimens.spaceXs,
        ),
        child: vertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [...sizeDots, const _Divider(), eraser],
                  ),
                  const _Divider(horizontal: true),
                  sticks,
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sticks,
                  const _Divider(),
                  eraser,
                  const _Divider(),
                  ...sizeDots,
                ],
              ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) => Container(
    width: horizontal ? 160 : 2,
    height: horizontal ? 2 : 48,
    margin: horizontal
        ? const EdgeInsets.symmetric(vertical: AppDimens.spaceXs)
        : const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
    color: AppColors.boardFrameDark,
  );
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
        radius: 22,
        child: SizedBox(
          width: 42,
          height: 34,
          child: Center(
            child: AnimatedContainer(
              duration: AppDimens.fast,
              transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
              width: 32,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
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

class _EraserButton extends StatelessWidget {
  const _EraserButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: AnimatedContainer(
          duration: AppDimens.fast,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.boardDark : AppColors.transparent,
            border: Border.all(
              color: selected ? AppColors.sunYellow : AppColors.transparent,
              width: 3,
            ),
          ),
          child: const Center(
            child: FaIcon(AppIcons.eraser, size: 26, color: AppColors.cream),
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

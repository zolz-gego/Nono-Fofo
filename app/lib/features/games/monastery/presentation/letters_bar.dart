import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../domain/hidden_letter.dart';

/// The letters to find, along the bottom: each exactly as it hides
/// (capital or small) with its name. Found ones are crossed out, faded and
/// ticked.
class LettersBar extends StatelessWidget {
  const LettersBar({super.key, required this.letters, required this.height});

  final List<HiddenLetter> letters;
  final double height;

  static const double _maxChip = 112;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Every chip the same width, as wide as fits (up to a limit).
          final n = max(1, letters.length);
          final w = min(_maxChip, constraints.maxWidth / n);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, l) in letters.indexed)
                SizedBox(
                  width: w,
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _LetterChip(
                      key: ValueKey('chip$i${l.found}'),
                      glyph: l.glyph,
                      name: l.letter.nameIn(lang),
                      found: l.found,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    super.key,
    required this.glyph,
    required this.name,
    required this.found,
  });

  final String glyph;
  final String name;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final nameStyle = AppTextStyles.of(
      Localizations.localeOf(context).languageCode == 'ar'
          ? AppScript.arabic
          : AppScript.english,
      AppTextVariant.caption,
    );
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceSm,
        vertical: AppDimens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: found
            ? AppColors.correct.withValues(alpha: 0.18)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: found ? AppColors.correct : AppColors.speechBubbleBorder,
          width: 2,
        ),
      ),
      child: FittedBox(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: found ? 0.45 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        glyph,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: AppFonts.coptic,
                          fontSize: 34,
                          height: 1.1,
                          color: AppColors.coptic,
                        ),
                      ),
                      if (found)
                        Container(width: 34, height: 3, color: AppColors.cocoa),
                    ],
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    style: nameStyle.copyWith(
                      decoration: found ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ),
            if (found)
              const PositionedDirectional(
                top: -4,
                end: -10,
                child: FaIcon(
                  AppIcons.passed,
                  size: 18,
                  color: AppColors.correct,
                ),
              ),
          ],
        ),
      ),
    );
    if (!found) return chip;
    return chip.animate().scale(
      begin: const Offset(1.25, 1.25),
      end: const Offset(1, 1),
      duration: 350.ms,
      curve: Curves.easeOutBack,
    );
  }
}

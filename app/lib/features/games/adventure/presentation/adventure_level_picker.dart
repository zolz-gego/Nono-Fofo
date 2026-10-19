import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../domain/adventure_level.dart';

/// One level on the picker.
class AdventureLevelCard {
  const AdventureLevelCard({
    required this.place,
    required this.stars,
    required this.unlocked,
  });

  final AdventurePlace place;

  /// Best stars (0 = not finished yet).
  final int stars;
  final bool unlocked;
}

/// The Adventure's start screen: three levels (each opens once the one
/// before is finished) with their best stars, and how to play.
class AdventureLevelPicker extends StatelessWidget {
  const AdventureLevelPicker({
    super.key,
    required this.levels,
    required this.touch,
    required this.onPick,
  });

  final List<AdventureLevelCard> levels;

  /// Explain the touch controls instead of the keyboard.
  final bool touch;
  final ValueChanged<int> onPick;

  static String placeName(AppLocalizations l10n, AdventurePlace place) =>
      switch (place) {
        AdventurePlace.nile => l10n.adventureLevelNile,
        AdventurePlace.desert => l10n.adventureLevelDesert,
        AdventurePlace.alexandria => l10n.adventureLevelAlexandria,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceLg,
                  vertical: AppDimens.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Column(
                  children: [
                    AppText.h2(
                      l10n.adventurePickLevel,
                      textAlign: TextAlign.center,
                    ),
                    AppText.body(
                      touch ? l10n.adventureHowToTouch : l10n.adventureHowTo,
                      color: AppColors.textMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
              Row(
                children: [
                  for (final (i, level) in levels.indexed) ...[
                    if (i > 0) const SizedBox(width: AppDimens.spaceMd),
                    Expanded(
                      child: _LevelCard(
                        number: i + 1,
                        card: level,
                        title: placeName(l10n, level.place),
                        onTap: () => onPick(i),
                      ),
                    ),
                  ],
                ],
              ),
            ].animate(interval: 80.ms).fadeIn().slideY(begin: 0.06),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  const _LevelCard({
    required this.number,
    required this.card,
    required this.title,
    required this.onTap,
  });

  final int number;
  final AdventureLevelCard card;
  final String title;
  final VoidCallback onTap;

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = widget.card.unlocked;
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: open ? AppColors.coral : AppColors.slateTeal,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: _hovered && open ? 18 : 8,
            offset: Offset(0, _hovered && open ? 8 : 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            // Wider (shorter) pictures on short screens, so all fits.
            aspectRatio: MediaQuery.sizeOf(context).shortestSide < 500
                ? 2.2
                : 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AssetPaths.adventureArt('bg_${widget.card.place.name}'),
                  fit: BoxFit.cover,
                ),
                PositionedDirectional(
                  top: AppDimens.spaceSm,
                  start: AppDimens.spaceSm,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surface,
                    child: AppText.h3('${widget.number}'),
                  ),
                ),
                if (!open)
                  ColoredBox(
                    color: AppColors.ink.withValues(alpha: 0.45),
                    child: const Center(
                      child: FaIcon(
                        AppIcons.locked,
                        size: 40,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.spaceSm),
            child: Column(
              children: [
                AppText.h3(widget.title, textAlign: TextAlign.center),
                const SizedBox(height: AppDimens.spaceXs),
                if (open)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3 coin stars, then any bonus stars in coral.
                      for (var i = 0; i < max(3, widget.card.stars); i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FaIcon(
                            i < widget.card.stars
                                ? AppIcons.star
                                : AppIcons.starEmpty,
                            size: i >= 3 ? 16 : 20,
                            color: i >= 3 ? AppColors.coral : AppColors.star,
                          ),
                        ),
                    ],
                  )
                else
                  AppText.body(
                    l10n.adventureLocked,
                    color: AppColors.textMuted,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return MouseRegion(
      cursor: open ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: open ? widget.onTap : null,
        child: Semantics(
          button: open,
          label: widget.title,
          child: AnimatedScale(
            scale: _hovered && open ? 1.04 : 1,
            duration: AppDimens.fast,
            curve: Curves.easeOutBack,
            child: card,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../../profile/presentation/profile_cubit.dart';
import '../../profile/presentation/profile_dialog.dart';
import '../domain/game_level.dart';

/// "Choose your level" on the home page: one card per [GameLevel]. Tapping a
/// card asks for the child's name and buddy the first time (they are saved
/// after that), then hands the level to [onStart].
class LevelSection extends StatelessWidget {
  const LevelSection({super.key, required this.onStart});

  final ValueChanged<GameLevel> onStart;

  static const double _threeColumnsFrom = 600;

  Future<void> _open(BuildContext context, GameLevel level) async {
    final sound = context.read<SoundService>()..play(SoundEvent.tap);
    final profiles = context.read<ProfileCubit>();
    if (profiles.state == null) {
      final profile = await ProfileDialog.show(context, level: level);
      if (profile == null) return;
      profiles.save(profile);
    } else {
      sound.play(SoundEvent.levelStart);
    }
    onStart(level);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = [
      for (final level in GameLevel.values)
        LevelCard(
          level: level,
          title: l10n.levelNumber(level.number),
          description: switch (level) {
            GameLevel.one => l10n.level1Desc,
            GameLevel.two => l10n.level2Desc,
            GameLevel.three => l10n.level3Desc,
          },
          onTap: () => _open(context, level),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.h2(l10n.chooseLevel, textAlign: TextAlign.center),
        const SizedBox(height: AppDimens.spaceMd),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= _threeColumnsFrom
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, card) in cards.indexed) ...[
                        if (i > 0) const SizedBox(width: AppDimens.spaceMd),
                        Expanded(child: card),
                      ],
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final (i, card) in cards.indexed) ...[
                      if (i > 0) const SizedBox(height: AppDimens.spaceMd),
                      card,
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// One level: number badge, stars for difficulty, title and a short
/// description. Grows under the mouse so it's clear it can be clicked.
class LevelCard extends StatefulWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final GameLevel level;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard> {
  bool _hovered = false;
  bool _pressed = false;

  static const double _hoverScale = 1.08;
  static const double _pressScale = 0.97;
  static const double _badgeSize = 72;

  Color get _accent => switch (widget.level) {
    GameLevel.one => AppColors.leafGreen,
    GameLevel.two => AppColors.sunYellow,
    GameLevel.three => AppColors.coral,
  };

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? _pressScale
        : _hovered
        ? _hoverScale
        : 1.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: '${widget.title}, ${widget.description}',
          child: AnimatedScale(
            scale: scale,
            duration: AppDimens.fast,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: AppDimens.fast,
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: _accent, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: _hovered ? 18 : 6,
                    offset: Offset(0, _hovered ? 8 : 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                    child: AppText.h1(
                      '${widget.level.number}',
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < GameLevel.values.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.spaceXs / 2,
                          ),
                          child: FaIcon(
                            AppIcons.star,
                            size: 18,
                            color: i < widget.level.number
                                ? AppColors.star
                                : AppColors.tertiary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  AppText.h2(widget.title, textAlign: TextAlign.center),
                  const SizedBox(height: AppDimens.spaceXs),
                  AppText.body(
                    widget.description,
                    color: AppColors.textMuted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

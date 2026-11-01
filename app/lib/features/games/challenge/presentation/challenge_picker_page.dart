import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/assets/asset_paths.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../levels/domain/game_level.dart';
import '../../../profile/presentation/profile_button.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../adventure/presentation/adventure_cubit.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../snakes_ladders/presentation/pyramids_background.dart';
import '../../snakes_ladders/presentation/snakes_cubit.dart';

/// The level's Challenge stop: pick Snakes & Ladders or the Adventure (more
/// challenges later). The stop gets its tick once both are done.
class ChallengePickerPage extends StatefulWidget {
  const ChallengePickerPage({super.key, required this.setup});

  final PlayerSetup setup;

  /// The challenge counts as done once every challenge game is.
  static bool done(GameProgressRepository progress, GameLevel level) =>
      progress.hasPassed(SnakesCubit.id, SnakesCubit.levelKey(level)) &&
      progress.hasPassed(AdventureCubit.id, AdventureCubit.doneKey(level));

  @override
  State<ChallengePickerPage> createState() => _ChallengePickerPageState();
}

class _ChallengePickerPageState extends State<ChallengePickerPage> {
  late final SoundService _sound = context.read<SoundService>();
  final GameProgressRepository _progress = sl<GameProgressRepository>();

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.pyramids);
  }

  void _open(String route) {
    _sound.play(SoundEvent.levelStart);
    // Back from a game: refresh the ticks.
    context.push(route).then((_) {
      if (!mounted) return;
      _sound.playMusic(MusicTrack.pyramids);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = widget.setup.level;
    final buddy = widget.setup.buddy;
    final opponent = buddy.other == CharacterId.nono ? l10n.nono : l10n.fofo;
    final cards = [
      _ChallengeCard(
        title: l10n.gameSnakes,
        body: l10n.challengeSnakesBody(opponent),
        icon: AppIcons.dice,
        accent: AppColors.leafGreen,
        heroes: [(buddy, 'cheer'), (buddy.other, 'wave')],
        done: _progress.hasPassed(SnakesCubit.id, SnakesCubit.levelKey(level)),
        onTap: () => _open(AppRoutes.challengeSnakes),
      ),
      _ChallengeCard(
        title: l10n.gameAdventure,
        body: l10n.challengeAdventureBody,
        icon: AppIcons.adventure,
        accent: AppColors.coral,
        heroes: const [(CharacterId.fofo, 'run'), (CharacterId.nono, 'run')],
        done: _progress.hasPassed(
          AdventureCubit.id,
          AdventureCubit.doneKey(level),
        ),
        onTap: () => _open(AppRoutes.challengeAdventure),
      ),
    ];
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameChallenge(opponent),
        onLogoTap: () => context.go(AppRoutes.home),
        actions: const [
          ProfileButton(),
          LanguageButton(),
          MuteButton(),
          SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PyramidsBackground()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spaceLg,
                        vertical: AppDimens.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      ),
                      child: AppText.h2(
                        l10n.challengePick,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppDimens.spaceLg),
                    LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth < 560) {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: AppDimens.spaceMd),
                              cards[1],
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: AppDimens.spaceLg),
                              Expanded(child: cards[1]),
                            ],
                          ),
                        );
                      },
                    ),
                  ].animate(interval: 80.ms).fadeIn().slideY(begin: 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  const _ChallengeCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.heroes,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String body;
  final FaIconData icon;
  final Color accent;

  /// The brothers on the card and their poses.
  final List<(CharacterId, String)> heroes;
  final bool done;
  final VoidCallback onTap;

  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.title,
          child: AnimatedScale(
            scale: _hovered ? 1.04 : 1,
            duration: AppDimens.fast,
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: widget.accent, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: _hovered ? 18 : 8,
                    offset: Offset(0, _hovered ? 8 : 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 150,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final (i, (id, pose)) in widget.heroes.indexed)
                              Transform.flip(
                                flipX: i == 1 && pose != 'run',
                                child: Image.asset(
                                  AssetPaths.characterPose(id.name, pose),
                                  height: id == CharacterId.nono ? 150 : 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(widget.icon, size: 22, color: widget.accent),
                          const SizedBox(width: AppDimens.spaceSm),
                          Flexible(
                            child: AppText.h2(
                              widget.title,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.spaceXs),
                      AppText.body(
                        widget.body,
                        color: AppColors.textMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (widget.done)
                    const PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: FaIcon(
                        AppIcons.passed,
                        size: 32,
                        color: AppColors.correct,
                      ),
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

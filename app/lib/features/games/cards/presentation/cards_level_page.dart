import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../levels/domain/game_level.dart';
import '../../../profile/presentation/profile_button.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../data/cards_config_repository.dart';
import '../domain/cards_config.dart';
import 'cards_cubit.dart';
import 'cards_page.dart';

/// Before Grandpa's Cards: the child picks how many cards to play with.
/// A solved size shows a green tick and its best time (with that run's
/// moves). Phones don't offer the biggest sizes.
class CardsLevelPage extends StatefulWidget {
  const CardsLevelPage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<CardsLevelPage> createState() => _CardsLevelPageState();
}

class _CardsLevelPageState extends State<CardsLevelPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _buddy = CharacterController(
    widget.setup.buddy,
    sound: _sound,
    initial: CharacterAction.hint,
  );
  final Future<CardsConfig> _config = sl<CardsConfigRepository>().load();
  final GameProgressRepository _progress = sl<GameProgressRepository>();

  static const double _maxWidth = 960;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buddy.say(context.l10n.cardsPickLevel);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  Future<void> _play(int count) async {
    _sound.play(SoundEvent.select);
    _buddy.play(CharacterAction.cheer, hold: const Duration(seconds: 1));
    await context.push(
      AppRoutes.cardsPlay,
      extra: CardsArgs(setup: widget.setup, count: count),
    );
    if (mounted) setState(() {}); // Show a new best time.
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.level(widget.setup.level));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameCards,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.backToGames,
            onPressed: _backToGames,
            icon: const FaIcon(AppIcons.road),
          ),
          const ProfileButton(),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: FutureBuilder<CardsConfig>(
        future: _config,
        builder: (context, snap) {
          final config = snap.data;
          if (config == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final levels = config.levelsFor(
            MediaQuery.sizeOf(context).shortestSide,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.spaceMd,
                  0,
                  AppDimens.spaceMd,
                  AppDimens.spaceXl,
                ),
                children: [
                  _header(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppDimens.spaceSm,
                    runSpacing: AppDimens.spaceSm,
                    children: [
                      for (final (i, n) in levels.indexed)
                        _LevelTile(
                              count: n,
                              best: _progress.bestTime(CardsCubit.id, '$n'),
                              onTap: () => _play(n),
                            )
                            .animate(delay: (60 * i).ms)
                            .fadeIn(duration: AppDimens.normal)
                            .scale(begin: const Offset(0.85, 0.85)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            // Room above the buddy for the speech bubble.
            padding: const EdgeInsets.only(top: 90),
            child: AnimatedCharacter(controller: _buddy, size: 130),
          ),
          const SizedBox(width: AppDimens.spaceLg),
          Expanded(child: AppText.h2(context.l10n.cardsPickLevel)),
        ],
      ),
    );
  }
}

/// One size to play: a little fan of cards, how many, and the best time.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.count,
    required this.best,
    required this.onTap,
  });

  final int count;
  final TimedRecord? best;
  final VoidCallback onTap;

  static const double _width = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final best = this.best;
    return SizedBox(
      width: _width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        elevation: 2,
        shadowColor: AppColors.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spaceMd),
            child: Column(
              children: [
                _CardFan(count: count),
                const SizedBox(height: AppDimens.spaceSm),
                AppText.h3(l10n.cardsCount(count)),
                const SizedBox(height: AppDimens.spaceXs),
                ConstrainedBox(
                  // Same height with or without a record, so tiles line up.
                  constraints: const BoxConstraints(minHeight: 56),
                  child: best == null
                      ? null
                      : Column(
                          children: [
                            const FaIcon(
                              AppIcons.passed,
                              size: 18,
                              color: AppColors.correct,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              l10n.cardsBest(best.clock, best.moves),
                              variant: AppTextVariant.caption,
                              color: AppColors.textMuted,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A few face-down cards, fanned out; more cards, wider fan.
class _CardFan extends StatelessWidget {
  const _CardFan({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final shown = switch (count) {
      <= 4 => 2,
      <= 8 => 3,
      <= 16 => 4,
      <= 32 => 5,
      _ => 6,
    };
    return SizedBox(
      height: 76,
      width: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < shown; i++)
            Transform.rotate(
              angle: (i - (shown - 1) / 2) * 0.22,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 44,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.deepTeal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.mistBlue, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

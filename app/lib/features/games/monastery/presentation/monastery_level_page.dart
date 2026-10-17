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
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../data/monastery_config_repository.dart';
import '../domain/monastery_config.dart';
import 'monastery_cubit.dart';
import 'monastery_page.dart';

/// Before Search the Monastery: the child picks how many letters hide.
/// A finished level shows a green tick and its best time (with that run's
/// wrong taps). Phones skip this page and always hide the same number.
class MonasteryLevelPage extends StatefulWidget {
  const MonasteryLevelPage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<MonasteryLevelPage> createState() => _MonasteryLevelPageState();
}

class _MonasteryLevelPageState extends State<MonasteryLevelPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _buddy = CharacterController(
    widget.setup.buddy,
    sound: _sound,
    initial: CharacterAction.hint,
  );
  final Future<MonasteryConfig> _config = sl<MonasteryConfigRepository>()
      .load();
  final GameProgressRepository _progress = sl<GameProgressRepository>();

  static const double _maxWidth = 960;

  /// Phones went straight on to the game.
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_skipped) _buddy.say(context.l10n.monasteryPickLevel);
    });
  }

  /// Phones don't pick: replace this page with the game.
  void _skipOnPhone(MonasteryConfig config) {
    if (_skipped) return;
    _skipped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.monasteryPlay,
        extra: MonasteryArgs(setup: widget.setup, count: config.phoneLetters),
      );
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
      AppRoutes.monasteryPlay,
      extra: MonasteryArgs(setup: widget.setup, count: count),
    );
    if (mounted) setState(() {}); // Show a new best time.
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.level, extra: widget.setup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameMonastery,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.backToGames,
            onPressed: _backToGames,
            icon: const FaIcon(AppIcons.road),
          ),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: FutureBuilder<MonasteryConfig>(
        future: _config,
        builder: (context, snap) {
          final config = snap.data;
          if (config == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (config.isSmallScreen(MediaQuery.sizeOf(context).shortestSide)) {
            _skipOnPhone(config);
            return const Center(child: CircularProgressIndicator());
          }
          final levels = config.letterCounts;
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
                              best: _progress.bestTime(MonasteryCubit.id, '$n'),
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
          Expanded(child: AppText.h2(context.l10n.monasteryPickLevel)),
        ],
      ),
    );
  }
}

/// One level: a magnifying glass over a few letters, how many, and the
/// best time.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.count,
    required this.best,
    required this.onTap,
  });

  final int count;
  final TimedRecord? best;
  final VoidCallback onTap;

  static const double _width = 140;

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
                _LetterPeek(count: count),
                const SizedBox(height: AppDimens.spaceSm),
                AppText.h3(l10n.monasteryCount(count)),
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
                              l10n.monasteryBest(best.clock, best.moves),
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

/// A few letters peeking out, and a magnifying glass; more letters, more
/// of them showing.
class _LetterPeek extends StatelessWidget {
  const _LetterPeek({required this.count});

  final int count;

  static const String _glyphs = 'abgdezyqiklmnxoprstu';

  @override
  Widget build(BuildContext context) {
    final shown = (count - 2).clamp(2, 8);
    return SizedBox(
      height: 76,
      width: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            Align(
              alignment: Alignment(-0.9 + (i % 4) * 0.6, i < 4 ? -0.6 : 0.7),
              child: Transform.rotate(
                angle: (i.isEven ? 1 : -1) * 0.3,
                child: Text(
                  _glyphs[(i * 3 + count) % _glyphs.length],
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: AppFonts.coptic,
                    fontSize: 26,
                    color: AppColors.monasteryNiche,
                  ),
                ),
              ),
            ),
          const FaIcon(AppIcons.found, size: 44, color: AppColors.deepTeal),
        ],
      ),
    );
  }
}

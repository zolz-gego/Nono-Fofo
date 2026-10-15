import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/character_id.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../../engines/characters/domain/character_action.dart';
import '../../../engines/characters/presentation/animated_character.dart';
import '../../../engines/characters/presentation/character_controller.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../../settings/presentation/language_button.dart';
import '../../settings/presentation/mute_button.dart';
import '../domain/game_level.dart';
import '../domain/level_game.dart';
import 'game_road.dart';

/// A level's games on a winding road, with the child's buddy at the bottom.
/// The games themselves come later; tapping one only says so for now.
class LevelGamesPage extends StatefulWidget {
  const LevelGamesPage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<LevelGamesPage> createState() => _LevelGamesPageState();
}

class _LevelGamesPageState extends State<LevelGamesPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _buddy = CharacterController(
    widget.setup.buddy,
    sound: _sound,
    initial: CharacterAction.wave,
  );

  static const double _maxWidth = 960;
  static const Duration _greetAfter = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.map);
    Future.delayed(_greetAfter, () {
      if (mounted) _buddy.say(context.l10n.pickGame);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  /// The game the buddy is standing at (or walking to).
  int _at = 0;

  /// Tapping a game sends the buddy running along the road to it; once
  /// there he says the game is coming soon.
  void _openGame(int index) {
    _sound.play(SoundEvent.tap);
    if (index == _at) return _arrived();
    _buddy
      ..hideSpeech()
      ..play(CharacterAction.run);
    setState(() => _at = index);
  }

  void _arrived() {
    _buddy
      ..play(CharacterAction.hint, hold: const Duration(seconds: 2))
      ..say(context.l10n.gameComingSoon(widget.setup.name));
  }

  RoadStop _stop(int index, LevelGame game, AppLocalizations l10n) {
    final opponent = widget.setup.buddy == CharacterId.nono
        ? l10n.fofo
        : l10n.nono;
    return switch (game) {
      LevelGame.fishing => RoadStop(
        image: game.name,
        placeholder: AppIcons.fishing,
        title: l10n.gameFishing,
        accent: AppColors.mistBlue,
        onTap: () => _openGame(index),
      ),
      LevelGame.writeLetter => RoadStop(
        image: game.name,
        placeholder: AppIcons.writeLetter,
        title: l10n.gameWriteLetter,
        accent: AppColors.sunYellow,
        onTap: () => _openGame(index),
      ),
      LevelGame.balloons => RoadStop(
        image: game.name,
        placeholder: AppIcons.balloons,
        title: l10n.gameBalloons,
        accent: AppColors.coral,
        onTap: () => _openGame(index),
      ),
      LevelGame.challenge => RoadStop(
        image: game.name,
        placeholder: AppIcons.challenge,
        title: l10n.gameChallenge(opponent),
        accent: AppColors.leafGreen,
        onTap: () => _openGame(index),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = LevelGame.of(widget.setup.level);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.levelNumber(widget.setup.level.number),
        onLogoTap: () => context.go(AppRoutes.home),
        actions: const [
          LanguageButton(),
          MuteButton(),
          SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            // Room under the last row for the buddy's feet.
            padding: const EdgeInsets.fromLTRB(
              AppDimens.spaceMd,
              AppDimens.spaceMd,
              AppDimens.spaceMd,
              AppDimens.spaceXl * 2,
            ),
            children:
                [
                      AppText.h1(
                        l10n.welcomeName(widget.setup.name),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.spaceLg),
                      if (games.isEmpty) ...[
                        AppText.body(
                          l10n.gamesComingSoon,
                          color: AppColors.textMuted,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.spaceXl * 2),
                        Center(child: AnimatedCharacter(controller: _buddy)),
                      ] else
                        GameRoad(
                          stops: [
                            for (final (i, g) in games.indexed)
                              _stop(i, g, l10n),
                          ],
                          walkerAt: _at,
                          onArrived: _arrived,
                          walker: (context, height, facingLeft) =>
                              AnimatedCharacter(
                                controller: _buddy,
                                size: height,
                                mirror: facingLeft,
                              ),
                        ),
                    ]
                    .animate(interval: 80.ms)
                    .fadeIn(duration: AppDimens.normal)
                    .slideY(begin: 0.06, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}

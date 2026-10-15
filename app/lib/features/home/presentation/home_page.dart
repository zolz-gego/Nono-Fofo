import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/character_id.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../../engines/characters/domain/character_action.dart';
import '../../../engines/characters/domain/character_reaction.dart';
import '../../../engines/characters/presentation/animated_character.dart';
import '../../../engines/characters/presentation/character_controller.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../../levels/domain/game_level.dart';
import '../../levels/presentation/level_section.dart';
import '../../settings/presentation/language_button.dart';
import '../../settings/presentation/mute_button.dart';

/// Home: what the app is, the brothers and their world, language switch
/// and a way into the About page.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _nono = CharacterController(
    CharacterId.nono,
    sound: _sound,
  );
  late final CharacterController _fofo = CharacterController(
    CharacterId.fofo,
    sound: _sound,
    initial: CharacterAction.hint,
  );

  static const double _maxWidth = 960;
  static const double _twoColumnsFrom = 720;

  /// The story starts at Grandpa's house, so that's the home theme.
  static const MusicTrack _music = MusicTrack.grandpaHouse;
  bool _retriedMusic = false;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(_music);
  }

  /// Browsers block audio until the first user gesture, so try again on the
  /// first tap (a no-op if the music is already playing).
  void _retryMusicOnce(PointerDownEvent _) {
    if (_retriedMusic) return;
    _retriedMusic = true;
    if (_sound.currentTrack == _music) _sound.playMusic(_music);
  }

  /// The games come in a later task; for now just confirm the choice.
  void _startLevel(PlayerSetup setup) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.gameComingSoon(setup.name))),
      );
  }

  @override
  void dispose() {
    _nono.dispose();
    _fofo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Listener(
      onPointerDown: _retryMusicOnce,
      child: Scaffold(
        appBar: AppTopBar(
          title: l10n.appTitle,
          actions: [
            const LanguageButton(),
            const MuteButton(),
            IconButton(
              tooltip: l10n.about,
              color: AppColors.textOnDark,
              onPressed: () => context.push(AppRoutes.about),
              icon: const FaIcon(AppIcons.info),
            ),
            const SizedBox(width: AppDimens.spaceSm),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              children:
                  [
                        const _Hero(),
                        const SizedBox(height: AppDimens.spaceLg),
                        AppText.h2(
                          l10n.meetBrothers,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        _brothers(l10n),
                        const SizedBox(height: AppDimens.spaceMd),
                        _TogetherBanner(text: l10n.together),
                        const SizedBox(height: AppDimens.spaceLg),
                        LevelSection(onStart: _startLevel),
                        const SizedBox(height: AppDimens.spaceLg),
                        const _Story(),
                        const SizedBox(height: AppDimens.spaceLg),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.about),
                            icon: const FaIcon(AppIcons.info),
                            label: Text(l10n.about),
                          ),
                        ),
                        const SizedBox(height: AppDimens.spaceLg),
                      ]
                      .animate(interval: 80.ms)
                      .fadeIn(duration: AppDimens.normal)
                      .slideY(begin: 0.06, curve: Curves.easeOut),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brothers(AppLocalizations l10n) {
    final nono = _BrotherCard(
      controller: _nono,
      name: l10n.nono,
      age: l10n.nonoAge,
      bio: l10n.nonoBio,
      catchphrase: l10n.nonoGreeting,
      accent: AppColors.nonoAccent,
    );
    final fofo = _BrotherCard(
      controller: _fofo,
      name: l10n.fofo,
      age: l10n.fofoAge,
      bio: l10n.fofoBio,
      catchphrase: l10n.fofoGreeting,
      accent: AppColors.fofoAccent,
      mirror: true,
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= _twoColumnsFrom
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: nono),
                  const SizedBox(width: AppDimens.spaceMd),
                  Expanded(child: fofo),
                ],
              ),
            )
          : Column(
              children: [
                nono,
                const SizedBox(height: AppDimens.spaceMd),
                fofo,
              ],
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          AppText.h1(
            l10n.homeTagline,
            color: AppColors.textOnDark,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceSm),
          AppText.body(
            l10n.homeIntro,
            color: AppColors.textOnDark,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceMd),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceMd,
              vertical: AppDimens.spaceSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.sunYellow,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(AppIcons.lessons, color: AppColors.ink),
                const SizedBox(width: AppDimens.spaceSm),
                Flexible(child: AppText(l10n.homeLessons)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrotherCard extends StatelessWidget {
  const _BrotherCard({
    required this.controller,
    required this.name,
    required this.age,
    required this.bio,
    required this.catchphrase,
    required this.accent,
    this.mirror = false,
  });

  final CharacterController controller;
  final String name;
  final String age;
  final String bio;
  final String catchphrase;
  final Color accent;
  final bool mirror;

  /// Nono's height; Fofo is drawn to the same scale (~75%).
  static const double _characterSize = 300;

  /// Headroom so jumps and raised arms stay inside the card (it clips).
  static const double _headroom = 80;

  /// Hold for reactions that otherwise never end (run, sleep).
  static const Duration _openEndedHold = Duration(seconds: 3);

  static final Random _random = Random();

  /// Plays a random reaction (pose + sound), never the one already showing.
  void _playRandom() {
    final options = CharacterReaction.values
        .where((r) => r.action != controller.action)
        .toList();
    final r = options[_random.nextInt(options.length)];
    if (r.hold != null) return controller.react(r);
    controller.play(r.action, hold: _openEndedHold);
    if (r.sound != null) {
      controller.sound?.play(r.sound!, by: controller.character);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.tertiary,
            height: _characterSize + _headroom,
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
            child: AnimatedCharacter(
              controller: controller,
              size: _characterSize,
              mirror: mirror,
              onTap: _playRandom,
            ),
          ),
          Container(height: 6, color: accent),
          Padding(
            padding: const EdgeInsets.all(AppDimens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.spaceSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppText.h2(name),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spaceSm,
                        vertical: AppDimens.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: AppText(age),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spaceSm),
                AppText.body(bio),
                const SizedBox(height: AppDimens.spaceMd),
                Row(
                  children: [
                    FaIcon(AppIcons.speech, color: accent),
                    const SizedBox(width: AppDimens.spaceSm),
                    Expanded(
                      child: AppText.h3(
                        '“$catchphrase”',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TogetherBanner extends StatelessWidget {
  const _TogetherBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: AppText.h3(
        text,
        color: AppColors.onSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.h2(l10n.ourStory),
            const SizedBox(height: AppDimens.spaceSm),
            AppText.body(l10n.storyHome),
            const SizedBox(height: AppDimens.spaceMd),
            AppText.h3(l10n.grandpa),
            const SizedBox(height: AppDimens.spaceXs),
            AppText.body(l10n.storyGrandpa),
            const SizedBox(height: AppDimens.spaceMd),
            AppText.h3(l10n.lostLetters),
            const SizedBox(height: AppDimens.spaceXs),
            AppText.body(l10n.storyAdventure),
          ],
        ),
      ),
    );
  }
}

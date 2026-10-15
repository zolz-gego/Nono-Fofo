import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/domain/character_id.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/typography/app_text_styles.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../../engines/characters/domain/character_action.dart';
import '../../../engines/characters/domain/character_reaction.dart';
import '../../../engines/characters/presentation/animated_character.dart';
import '../../../engines/characters/presentation/character_controller.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_cubit.dart';

/// Playground of what's built so far: the text components, both characters
/// with every pose/reaction, the sound engine and settings. Shown on the
/// About page below [header].
class PlaygroundView extends StatefulWidget {
  const PlaygroundView({super.key, this.header});

  /// Shown above the playground sections, scrolling with them.
  final Widget? header;

  @override
  State<PlaygroundView> createState() => _PlaygroundViewState();
}

class _PlaygroundViewState extends State<PlaygroundView> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _nono = CharacterController(
    CharacterId.nono,
    sound: _sound,
  );
  late final CharacterController _fofo = CharacterController(
    CharacterId.fofo,
    sound: _sound,
  );
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void dispose() {
    _nono.dispose();
    _fofo.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _react(CharacterReaction r) {
    _nono.react(r);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fofo.react(r, withSound: false);
    });
    if (r == CharacterReaction.celebrate || r == CharacterReaction.win) {
      _confetti.play();
      _sound.play(SoundEvent.confetti);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ListView(
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          children:
              [
                    ?widget.header,
                    _Section(
                      title: l10n.sectionCharacters,
                      child: _stage(l10n),
                    ),
                    _Section(
                      title: l10n.sectionTexts,
                      child: const _TextsDemo(),
                    ),
                    _Section(
                      title: l10n.sectionSounds,
                      child: _SoundsDemo(_sound),
                    ),
                    _Section(
                      title: l10n.sectionSettings,
                      child: const _SettingsDemo(),
                    ),
                  ]
                  .animate(interval: 80.ms)
                  .fadeIn(duration: AppDimens.normal)
                  .slideY(begin: 0.08, curve: Curves.easeOut),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          colors: AppColors.celebration,
          numberOfParticles: 30,
        ),
      ],
    );
  }

  Widget _stage(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          height: 330,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCharacter(controller: _nono, size: 240),
              AnimatedCharacter(controller: _fofo, size: 240, mirror: true),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spaceMd),
        Wrap(
          spacing: AppDimens.spaceSm,
          runSpacing: AppDimens.spaceSm,
          alignment: WrapAlignment.center,
          children: [
            for (final r in CharacterReaction.values)
              FilledButton(onPressed: () => _react(r), child: Text(r.name)),
            OutlinedButton(
              onPressed: () {
                _nono.say(l10n.nonoGreeting);
                _fofo.say(l10n.fofoGreeting);
              },
              child: const Text('say'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spaceSm),
        Wrap(
          spacing: AppDimens.spaceXs,
          runSpacing: AppDimens.spaceXs,
          alignment: WrapAlignment.center,
          children: [
            for (final a in CharacterAction.values)
              OutlinedButton(
                onPressed: () {
                  _nono.play(a);
                  _fofo.play(a);
                },
                child: Text(a.name),
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.h2(title),
            const SizedBox(height: AppDimens.spaceSm),
            child,
          ],
        ),
      ),
    );
  }
}

class _TextsDemo extends StatelessWidget {
  const _TextsDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CopticText.h1('Aa Bb Gg Dd'),
        CopticText.h2('Ee Zz Hh Qq'),
        CopticText.h3('Ii Kk Ll Mm'),
        CopticText.body('abgdezyqiklmnxoprctuvf,\'w'),
        Divider(),
        ArabicText.h1('يلا نتعلم الحروف القبطي!'),
        ArabicText.h2('نونو وفوفو'),
        ArabicText.h3('عنوان صغير'),
        ArabicText.body('نونو بيجري بسرعة، وفوفو بيفكر الأول.'),
        ArabicText('ملاحظة صغيرة', variant: AppTextVariant.caption),
        Divider(),
        EnglishText.h1("Let's learn Coptic!"),
        EnglishText.h2('Nono & Fofo'),
        EnglishText.h3('Small header'),
        EnglishText.body('Nono runs fast, and Fofo thinks first.'),
        EnglishText('A small caption', variant: AppTextVariant.caption),
      ],
    );
  }
}

class _SoundsDemo extends StatefulWidget {
  const _SoundsDemo(this.sound);

  final SoundService sound;

  @override
  State<_SoundsDemo> createState() => _SoundsDemoState();
}

class _SoundsDemoState extends State<_SoundsDemo> {
  static const _events = [
    SoundEvent.tap,
    SoundEvent.correctAnswer,
    SoundEvent.wrongAnswer,
    SoundEvent.hint,
    SoundEvent.star3,
    SoundEvent.levelComplete,
    SoundEvent.unlock,
    SoundEvent.coin,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playing = widget.sound.currentTrack != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppDimens.spaceSm,
          runSpacing: AppDimens.spaceSm,
          children: [
            for (final e in _events)
              OutlinedButton(
                onPressed: () => widget.sound.play(e, by: CharacterId.nono),
                child: Text(e.name),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.spaceSm),
        Wrap(
          spacing: AppDimens.spaceSm,
          runSpacing: AppDimens.spaceSm,
          children: [
            for (final t in MusicTrack.values)
              OutlinedButton(
                onPressed: () async {
                  await widget.sound.playMusic(t);
                  setState(() {});
                },
                child: Text(t.name),
              ),
            FilledButton.icon(
              onPressed: playing
                  ? () async {
                      await widget.sound.stopMusic();
                      setState(() {});
                    }
                  : null,
              icon: const FaIcon(AppIcons.stop),
              label: Text(l10n.stopMusic),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsDemo extends StatelessWidget {
  const _SettingsDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return BlocBuilder<SettingsCubit, AppSettings>(
      builder: (context, s) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: AppText(l10n.language)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('عربي')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {s.languageCode},
                onSelectionChanged: (v) => cubit.setLanguage(v.first),
              ),
            ],
          ),
          _volume(
            l10n.music,
            s.musicVolume,
            (v) => cubit.setVolume(SoundChannel.music, v),
          ),
          _volume(
            l10n.effects,
            s.sfxVolume,
            (v) => cubit.setVolume(SoundChannel.sfx, v),
          ),
          _volume(
            l10n.voices,
            s.voiceVolume,
            (v) => cubit.setVolume(SoundChannel.voice, v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: AppText(l10n.mute),
            value: s.muted,
            onChanged: cubit.setMuted,
          ),
        ],
      ),
    );
  }

  Widget _volume(String label, double value, ValueChanged<double> onChanged) =>
      Row(
        children: [
          SizedBox(width: 110, child: AppText(label)),
          Expanded(
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      );
}

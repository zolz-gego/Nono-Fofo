import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import 'game_settings_dialog.dart';

/// A game's own action (another letter, another level, …). It shows in the
/// settings pop-up while playing and in the top bar on the game's pickers.
class GameAction {
  const GameAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FaIconData icon;

  /// Read in the current language, so it follows a switch in the pop-up.
  final String Function(AppLocalizations l10n) label;
  final VoidCallback onPressed;
}

/// The page frame of every game. Use it instead of a [Scaffold] with an
/// [AppTopBar].
///
/// While [playing], the game fills the whole screen (the phone's status and
/// navigation bars hide too) and a see-through settings button sits in the
/// top corner: top left in Arabic, top right in English. It pauses the game
/// ([onPause]) and opens a pop-up with resume, the game's [actions], home,
/// language and sound; closing it calls [onResume].
///
/// Before the game starts (a picker inside the page), [playing] is false and
/// the page has the usual top bar with the same [actions].
class GameScaffold extends StatefulWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.playing = true,
    this.onPause,
    this.onResume,
  });

  final String title;
  final Widget body;
  final List<GameAction> actions;
  final bool playing;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  /// Space the settings button takes in its corner. Game HUDs leave this
  /// much room at the top end.
  static const double buttonSize = 48;
  static const double buttonInset = AppDimens.spaceSm;
  static const double cornerSize = buttonSize + buttonInset * 2;

  @override
  State<GameScaffold> createState() => GameScaffoldState();
}

class GameScaffoldState extends State<GameScaffold> {
  bool _paused = false;
  bool? _fullScreen;

  @override
  void initState() {
    super.initState();
    _syncSystemBars();
  }

  @override
  void didUpdateWidget(GameScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSystemBars();
  }

  @override
  void dispose() {
    if (_fullScreen ?? false) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  /// Hides the phone's status and navigation bars while playing (no effect
  /// on the web).
  void _syncSystemBars() {
    if (_fullScreen == widget.playing) return;
    _fullScreen = widget.playing;
    SystemChrome.setEnabledSystemUIMode(
      widget.playing ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  /// Pauses the game and opens the settings pop-up (also for a game's own
  /// shortcut, like Esc).
  Future<void> openSettings() async {
    if (_paused || !widget.playing) return;
    final sound = context.read<SoundService>();
    sound.play(SoundEvent.popupOpen);
    setState(() => _paused = true);
    widget.onPause?.call();
    final picked = await showGameSettings(
      context,
      actions: [
        ...widget.actions,
        GameAction(
          icon: AppIcons.home,
          label: (l) => l.gameHome,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
    if (!mounted) return;
    setState(() => _paused = false);
    widget.onResume?.call();
    if (picked == null) {
      sound.play(SoundEvent.popupClose);
    } else {
      sound.play(SoundEvent.tap);
      picked();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.playing) {
      return Scaffold(
        appBar: AppTopBar(
          title: widget.title,
          onLogoTap: () => context.go(AppRoutes.home),
          actions: [
            for (final a in widget.actions)
              IconButton(
                tooltip: a.label(context.l10n),
                onPressed: a.onPressed,
                icon: FaIcon(a.icon),
              ),
            const LanguageButton(),
            const MuteButton(),
            const SizedBox(width: AppDimens.spaceSm),
          ],
        ),
        body: widget.body,
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: TickerMode(enabled: !_paused, child: widget.body),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(GameScaffold.buttonInset),
                child: _SettingsButton(onPressed: openSettings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round, see-through gear: the game shows through it.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.gameSettings,
      child: Material(
        color: AppColors.ink.withValues(alpha: 0.3),
        shape: CircleBorder(
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: GameScaffold.buttonSize,
            child: Center(
              child: FaIcon(
                AppIcons.settings,
                size: 22,
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

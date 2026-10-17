import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';

/// The start screen: play the other brother (the computer), or a friend on
/// this device (who types their name first).
class SnakesModePicker extends StatelessWidget {
  const SnakesModePicker({
    super.key,
    required this.buddy,
    required this.onComputer,
    required this.onFriend,
  });

  /// The child's brother; the other one is the opponent.
  final CharacterId buddy;
  final VoidCallback onComputer;
  final ValueChanged<String> onFriend;

  String _name(AppLocalizations l10n, CharacterId id) =>
      id == CharacterId.nono ? l10n.nono : l10n.fofo;

  Future<void> _askFriend(BuildContext context) async {
    final sound = context.read<SoundService>()..play(SoundEvent.popupOpen);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _FriendNameDialog(hero: _name(context.l10n, buddy.other)),
    );
    if (name == null) {
      sound.play(SoundEvent.popupClose);
      return;
    }
    onFriend(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final opponent = buddy.other;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
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
                  l10n.snakesPickMode,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
              LayoutBuilder(
                builder: (context, c) {
                  final cards = [
                    _ModeCard(
                      icon: AppIcons.vsComputer,
                      title: l10n.snakesVsComputer(_name(l10n, opponent)),
                      body: l10n.snakesVsComputerBody(_name(l10n, opponent)),
                      accent: AppColors.leafGreen,
                      characters: [buddy, opponent],
                      onTap: () {
                        context.read<SoundService>().play(
                          SoundEvent.levelStart,
                        );
                        onComputer();
                      },
                    ),
                    _ModeCard(
                      icon: AppIcons.withFriend,
                      title: l10n.snakesWithFriend,
                      body: l10n.snakesWithFriendBody,
                      accent: AppColors.coral,
                      characters: [buddy, opponent],
                      onTap: () {
                        context.read<SoundService>().play(SoundEvent.tap);
                        _askFriend(context);
                      },
                    ),
                  ];
                  if (c.maxWidth < 520) {
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
    );
  }
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.characters,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String body;
  final Color accent;
  final List<CharacterId> characters;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (i, id) in widget.characters.indexed)
                          Transform.flip(
                            flipX: i == 1,
                            child: Image.asset(
                              AssetPaths.characterPose(
                                id.name,
                                i == 0 ? 'cheer' : 'wave',
                              ),
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks the friend's name; returns it, or null if closed.
class _FriendNameDialog extends StatefulWidget {
  const _FriendNameDialog({required this.hero});

  /// The brother whose token the friend moves.
  final String hero;

  @override
  State<_FriendNameDialog> createState() => _FriendNameDialogState();
}

class _FriendNameDialogState extends State<_FriendNameDialog> {
  final TextEditingController _name = TextEditingController();

  static const int _maxNameLength = 20;

  String get _trimmed => _name.text.trim();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    if (_trimmed.isEmpty) return;
    context.read<SoundService>().play(SoundEvent.levelStart);
    Navigator.of(context).pop(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: AppText.h2(l10n.snakesFriendName)),
                  IconButton(
                    tooltip: l10n.cancel,
                    color: AppColors.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(AppIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              TextField(
                controller: _name,
                autofocus: true,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _start(),
                decoration: InputDecoration(
                  hintText: l10n.nameHint,
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spaceSm),
              AppText.body(
                l10n.snakesFriendPlaysAs(widget.hero),
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppDimens.spaceLg),
              FilledButton.icon(
                onPressed: _trimmed.isEmpty ? null : _start,
                icon: const FaIcon(AppIcons.play),
                label: Text(l10n.letsPlay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

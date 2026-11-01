import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/assets/asset_paths.dart';
import '../../../core/domain/character_id.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../../levels/domain/game_level.dart';
import '../domain/player_profile.dart';

/// Popup where the child types their name and picks which brother to play
/// with. Before a [level] it starts playing ("Let's play!"); without one
/// (the top bar's profile button) it edits the saved [initial] profile.
/// Returns null if closed without saving.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key, this.level, this.initial, this.onDone});

  final GameLevel? level;
  final PlayerProfile? initial;

  /// Gets the result (null if closed) when the dialog is part of a page
  /// rather than pushed with [show]; otherwise it pops with it.
  final ValueChanged<PlayerProfile?>? onDone;

  static Future<PlayerProfile?> show(
    BuildContext context, {
    GameLevel? level,
    PlayerProfile? initial,
  }) {
    final sound = context.read<SoundService>()..play(SoundEvent.popupOpen);
    return showDialog<PlayerProfile>(
      context: context,
      builder: (_) => ProfileDialog(level: level, initial: initial),
    ).then((profile) {
      if (profile == null) sound.play(SoundEvent.popupClose);
      return profile;
    });
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late CharacterId? _buddy = widget.initial?.buddy;

  static const double _maxWidth = 480;
  static const int _maxNameLength = 20;

  late final SoundService _sound = context.read<SoundService>();

  String get _trimmedName => _name.text.trim();
  bool get _canStart => _trimmedName.isNotEmpty && _buddy != null;

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

  void _pick(CharacterId id) {
    if (_buddy == id) return;
    setState(() => _buddy = id);
    _sound.play(SoundEvent.select, by: id);
  }

  void _start() {
    if (!_canStart) return;
    _sound.play(widget.level == null ? SoundEvent.tap : SoundEvent.levelStart);
    _done(PlayerProfile(name: _trimmedName, buddy: _buddy!));
  }

  void _done(PlayerProfile? profile) {
    final onDone = widget.onDone;
    if (onDone == null) return Navigator.of(context).pop(profile);
    if (profile == null) _sound.play(SoundEvent.popupClose);
    onDone(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = widget.level;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText.h2(
                      level == null
                          ? l10n.profileTitle
                          : l10n.levelNumber(level.number),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancel,
                    color: AppColors.textMuted,
                    onPressed: () => _done(null),
                    icon: const FaIcon(AppIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceMd),
              AppText.h3(l10n.yourName),
              const SizedBox(height: AppDimens.spaceSm),
              TextField(
                controller: _name,
                autofocus: widget.initial == null,
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
              const SizedBox(height: AppDimens.spaceLg),
              AppText.h3(l10n.playWith),
              const SizedBox(height: AppDimens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _BuddyOption(
                      id: CharacterId.nono,
                      name: l10n.nono,
                      accent: AppColors.nonoAccent,
                      selected: _buddy == CharacterId.nono,
                      onTap: () => _pick(CharacterId.nono),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceMd),
                  Expanded(
                    child: _BuddyOption(
                      id: CharacterId.fofo,
                      name: l10n.fofo,
                      accent: AppColors.fofoAccent,
                      selected: _buddy == CharacterId.fofo,
                      onTap: () => _pick(CharacterId.fofo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceLg),
              FilledButton.icon(
                onPressed: _canStart ? _start : null,
                icon: FaIcon(level == null ? AppIcons.check : AppIcons.play),
                label: Text(level == null ? l10n.save : l10n.letsPlay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One brother to pick: cheers when selected, grows a little on hover.
class _BuddyOption extends StatefulWidget {
  const _BuddyOption({
    required this.id,
    required this.name,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final CharacterId id;
  final String name;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BuddyOption> createState() => _BuddyOptionState();
}

class _BuddyOptionState extends State<_BuddyOption> {
  bool _hovered = false;

  static const double _imageHeight = 140;
  static const double _hoverScale = 1.05;

  @override
  Widget build(BuildContext context) {
    final pose = widget.selected ? 'cheer' : 'idle';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: widget.name,
          child: AnimatedScale(
            scale: _hovered || widget.selected ? _hoverScale : 1,
            duration: AppDimens.fast,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: AppDimens.fast,
              padding: const EdgeInsets.all(AppDimens.spaceSm),
              decoration: BoxDecoration(
                color: widget.selected
                    ? widget.accent.withValues(alpha: 0.25)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: widget.selected ? widget.accent : AppColors.tertiary,
                  width: widget.selected ? 4 : 2,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: _imageHeight,
                    child: Image.asset(
                      AssetPaths.characterPose(widget.id.name, pose),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.selected) ...[
                        FaIcon(AppIcons.check, size: 18, color: widget.accent),
                        const SizedBox(width: AppDimens.spaceXs),
                      ],
                      AppText.h3(widget.name),
                    ],
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/assets/asset_paths.dart';
import '../../../core/domain/character_id.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../domain/player_profile.dart';
import 'profile_cubit.dart';
import 'profile_dialog.dart';

/// Top-bar button with the buddy's face and the child's name (just an icon
/// before a profile is set). Opens the profile pop-up to change them.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  static const double _avatarSize = 36;

  /// Hide the name on narrow screens, where the top bar is crowded.
  static const double _showNameFrom = 600;

  Future<void> _edit(BuildContext context, PlayerProfile? profile) async {
    final cubit = context.read<ProfileCubit>();
    final next = await ProfileDialog.show(context, initial: profile);
    if (next != null) cubit.save(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProfileCubit, PlayerProfile?>(
      builder: (context, profile) {
        final showName =
            profile != null &&
            MediaQuery.sizeOf(context).width >= _showNameFrom;
        return Tooltip(
          message: l10n.changeProfile,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textOnDark,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spaceSm,
              ),
            ),
            onPressed: () => _edit(context, profile),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile == null)
                  const FaIcon(AppIcons.profile)
                else
                  _Avatar(buddy: profile.buddy, size: _avatarSize),
                if (showName) ...[
                  const SizedBox(width: AppDimens.spaceSm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(profile.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The buddy's face in a circle of his colour.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.buddy, required this.size});

  final CharacterId buddy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = buddy == CharacterId.nono
        ? AppColors.nonoAccent
        : AppColors.fofoAccent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: accent, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      // The idle pose, zoomed in on the head.
      child: Transform.scale(
        scale: 2.2,
        alignment: const Alignment(0, -0.85),
        child: Image.asset(
          AssetPaths.characterPose(buddy.name, 'idle'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../assets/asset_paths.dart';
import '../theme/app_dimens.dart';

/// The app's top bar: the round Nono & Fofo logo next to the page title.
/// Use it as `Scaffold.appBar` on every screen.
///
/// There is no back arrow: on inner pages pass [onLogoTap] to go home, the
/// way a website logo works.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title, this.actions, this.onLogoTap});

  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onLogoTap;

  static const double height = 68;
  static const double logoSize = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final logo = Image.asset(
      AssetPaths.logo,
      width: logoSize,
      height: logoSize,
      semanticLabel: 'Nono & Fofo',
    );
    return AppBar(
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      actions: actions,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onLogoTap == null)
            logo
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onLogoTap, child: logo),
            ),
          if (title != null) ...[
            const SizedBox(width: AppDimens.spaceSm),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    );
  }
}

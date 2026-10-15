import 'package:flutter/material.dart';

import '../assets/asset_paths.dart';
import '../theme/app_dimens.dart';

/// The app's top bar: the round Nono & Fofo logo next to the page title.
/// Use it as `Scaffold.appBar` on every screen.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  static const double height = 68;
  static const double logoSize = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return AppBar(
      toolbarHeight: height,
      actions: actions,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetPaths.logo,
            width: logoSize,
            height: logoSize,
            semanticLabel: 'Nono & Fofo',
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

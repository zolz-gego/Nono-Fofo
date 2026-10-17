import 'package:flutter/material.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';

/// The Pyramids scene behind the board: the tall picture on tall screens
/// (when there is one), else the wide one, cropped to fill.
class PyramidsBackground extends StatelessWidget {
  const PyramidsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        Widget wide() => Image.asset(
          AssetPaths.snakesBackground,
          fit: BoxFit.cover,
          // The Pyramids stand on the left of the wide picture.
          alignment: Alignment.centerLeft,
          errorBuilder: (_, _, _) =>
              const ColoredBox(color: AppColors.pyramidDune),
        );
        return SizedBox.expand(
          child: c.maxWidth < c.maxHeight
              ? Image.asset(
                  AssetPaths.snakesBackgroundTall,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => wide(),
                )
              : wide(),
        );
      },
    );
  }
}

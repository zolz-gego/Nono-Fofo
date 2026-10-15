import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/text/app_texts.dart';
import '../../playground/presentation/playground_view.dart';
import '../../settings/presentation/language_button.dart';

/// About: what the app is and where it's heading, followed by a playground
/// of everything implemented so far.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.aboutTitle,
        actions: const [
          LanguageButton(),
          SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: PlaygroundView(
        header: Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.spaceLg),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: AppText.body(
                  l10n.aboutBody,
                  color: AppColors.textOnDark,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
              AppText.h2(l10n.aboutTryTitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

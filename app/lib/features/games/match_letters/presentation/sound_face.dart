import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/text/app_texts.dart';

/// A sound: an Arabic letter, a haraka with its name under it in brackets
/// (e.g. "(فتحة)"), or Latin letters in the English app.
class SoundFace extends StatelessWidget {
  const SoundFace({super.key, required this.sound, required this.lang});

  final String sound;
  final String lang;

  /// The haraka's name, when [sound] is one (written on a tatweel).
  String? _haraka(BuildContext context) {
    final l10n = context.l10n;
    return switch (sound.replaceAll('ـ', '')) {
      'َ' => l10n.harakaFatha,
      'ِ' => l10n.harakaKasra,
      'ُ' => l10n.harakaDamma,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final haraka = _haraka(context);
    if (haraka != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArabicText.h1(sound, color: AppColors.ink),
          ArabicText.h3('($haraka)', color: AppColors.cocoa),
        ],
      );
    }
    return lang == 'ar'
        ? ArabicText.h1(sound, color: AppColors.ink)
        : EnglishText.h1(sound, color: AppColors.ink);
  }
}

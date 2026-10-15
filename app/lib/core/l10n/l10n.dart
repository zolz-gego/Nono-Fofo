import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Supported UI languages. Arabic is the default.
/// To add a language: add `app_<code>.arb` in `arb/` and list it here.
abstract final class AppLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');
  static const Locale fallback = arabic;
  static const List<Locale> supported = [arabic, english];
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

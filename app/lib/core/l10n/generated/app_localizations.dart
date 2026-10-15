import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name
  ///
  /// In ar, this message translates to:
  /// **'نونو وفوفو'**
  String get appTitle;

  /// Developer playground screen title
  ///
  /// In ar, this message translates to:
  /// **'ملعب التجارب'**
  String get playgroundTitle;

  /// No description provided for @sectionTexts.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط'**
  String get sectionTexts;

  /// No description provided for @sectionCharacters.
  ///
  /// In ar, this message translates to:
  /// **'نونو وفوفو'**
  String get sectionCharacters;

  /// No description provided for @sectionSounds.
  ///
  /// In ar, this message translates to:
  /// **'الأصوات'**
  String get sectionSounds;

  /// No description provided for @sectionSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get sectionSettings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @music.
  ///
  /// In ar, this message translates to:
  /// **'الموسيقى'**
  String get music;

  /// No description provided for @effects.
  ///
  /// In ar, this message translates to:
  /// **'المؤثرات'**
  String get effects;

  /// No description provided for @voices.
  ///
  /// In ar, this message translates to:
  /// **'الأصوات'**
  String get voices;

  /// No description provided for @mute.
  ///
  /// In ar, this message translates to:
  /// **'كتم الصوت'**
  String get mute;

  /// No description provided for @nono.
  ///
  /// In ar, this message translates to:
  /// **'نونو'**
  String get nono;

  /// No description provided for @fofo.
  ///
  /// In ar, this message translates to:
  /// **'فوفو'**
  String get fofo;

  /// No description provided for @sampleHeader.
  ///
  /// In ar, this message translates to:
  /// **'يلا نتعلم الحروف القبطي!'**
  String get sampleHeader;

  /// No description provided for @sampleBody.
  ///
  /// In ar, this message translates to:
  /// **'نونو بيجري بسرعة، وفوفو بيفكر الأول.'**
  String get sampleBody;

  /// No description provided for @nonoGreeting.
  ///
  /// In ar, this message translates to:
  /// **'يلا بينا!'**
  String get nonoGreeting;

  /// No description provided for @fofoGreeting.
  ///
  /// In ar, this message translates to:
  /// **'استنى نفكر شوية'**
  String get fofoGreeting;

  /// No description provided for @playMusic.
  ///
  /// In ar, this message translates to:
  /// **'شغّل الموسيقى'**
  String get playMusic;

  /// No description provided for @stopMusic.
  ///
  /// In ar, this message translates to:
  /// **'وقّف الموسيقى'**
  String get stopMusic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

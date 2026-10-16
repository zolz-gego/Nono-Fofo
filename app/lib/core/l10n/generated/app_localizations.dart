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

  /// No description provided for @unmute.
  ///
  /// In ar, this message translates to:
  /// **'شغّل الصوت'**
  String get unmute;

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

  /// Language button label: the name of the OTHER language to switch to
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get switchLanguage;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get about;

  /// No description provided for @homeTagline.
  ///
  /// In ar, this message translates to:
  /// **'يلا نتعلم ونلعب مع نونو وفوفو!'**
  String get homeTagline;

  /// No description provided for @homeIntro.
  ///
  /// In ar, this message translates to:
  /// **'الحروف القبطي اتبعترت في كل حتة في مصر! تعالى مع نونو وفوفو نلاقيها ونرجعها لكتاب جدو.'**
  String get homeIntro;

  /// No description provided for @homeLessons.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي بنتعلم الحروف القبطي، وقريب هيبقى في دروس تانية كتير!'**
  String get homeLessons;

  /// No description provided for @meetBrothers.
  ///
  /// In ar, this message translates to:
  /// **'تعرّف على نونو وفوفو'**
  String get meetBrothers;

  /// No description provided for @nonoAge.
  ///
  /// In ar, this message translates to:
  /// **'٩ سنين'**
  String get nonoAge;

  /// No description provided for @fofoAge.
  ///
  /// In ar, this message translates to:
  /// **'٦ سنين'**
  String get fofoAge;

  /// No description provided for @nonoBio.
  ///
  /// In ar, this message translates to:
  /// **'نونو الأخ الكبير. شعره كيرلي غامق وضحكته واسعة، ومليان طاقة. مبيمشيش، دايماً بيجري! بيحب الكورة والسباقات، وأول واحد بيرفع إيده يجاوب. ساعات بيستعجل ويغلط، بس بيضحك ويحاول تاني ومبيزهقش أبداً. وبيحب أخوه الصغير جداً، ودايماً بيشجعه.'**
  String get nonoBio;

  /// No description provided for @fofoBio.
  ///
  /// In ar, this message translates to:
  /// **'فوفو الأخ الصغير. شعره كيرلي لونه كراميل، وسنته اللي قدام واقعة. هادي وشاطر، ولما بيفكر بيحط صباعه على دقنه. بيحب الألغاز والرسم وبيسأل \"ليه؟\" على كل حاجة. بياخد وقته، بس لما بيجاوب غالباً بيبقى صح، وبيلاحظ حاجات صغيرة محدش بياخد باله منها.'**
  String get fofoBio;

  /// No description provided for @together.
  ///
  /// In ar, this message translates to:
  /// **'نونو بيجيب الشجاعة، وفوفو بيجيب الأفكار، ومع بعض مفيش حرف يستخبى منهم!'**
  String get together;

  /// No description provided for @ourStory.
  ///
  /// In ar, this message translates to:
  /// **'حكايتنا'**
  String get ourStory;

  /// No description provided for @storyHome.
  ///
  /// In ar, this message translates to:
  /// **'نونو وفوفو أخين مصريين عايشين مع بابا وماما في القاهرة. كل جمعة بيروحوا بيت جدو، أحلى بيت في الدنيا، مليان كتب قديمة وحكايات.'**
  String get storyHome;

  /// No description provided for @grandpa.
  ///
  /// In ar, this message translates to:
  /// **'جدو'**
  String get grandpa;

  /// No description provided for @storyGrandpa.
  ///
  /// In ar, this message translates to:
  /// **'جدو طيب وهادي وبيعرف حكايات كتير. عنده كتاب قبطي قديم جداً، حروفه بتلمع زي الدهب.'**
  String get storyGrandpa;

  /// No description provided for @lostLetters.
  ///
  /// In ar, this message translates to:
  /// **'الحروف التايهة'**
  String get lostLetters;

  /// No description provided for @storyAdventure.
  ///
  /// In ar, this message translates to:
  /// **'في يوم، نونو دخل بيت جدو جري زي عادته… وخبط في الكتاب! الكتاب وقع واتفتح، والحروف طارت واتبعترت في كل حتة في مصر: على النيل، في القرية، عند الأهرامات، في الدير اللي في الصحرا، ولحد إسكندرية والبحر. ومن ساعتها نونو وفوفو بيلفوا مصر كلها يدوروا على الحروف ويرجعوها للكتاب.'**
  String get storyAdventure;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن نونو وفوفو'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'نونو وفوفو تطبيق بيعلّم الأطفال من خلال ألعاب وحكايات. دلوقتي بنبدأ بالحروف القبطي، وبعد كده هيبقى في دروس تانية كتير. التطبيق لسه بيتبني، والجاي أحلى!'**
  String get aboutBody;

  /// No description provided for @aboutTryTitle.
  ///
  /// In ar, this message translates to:
  /// **'جرّب اللي جاهز لحد دلوقتي'**
  String get aboutTryTitle;

  /// No description provided for @chooseLevel.
  ///
  /// In ar, this message translates to:
  /// **'اختار المستوى'**
  String get chooseLevel;

  /// No description provided for @levelNumber.
  ///
  /// In ar, this message translates to:
  /// **'المستوى {number}'**
  String levelNumber(int number);

  /// No description provided for @level1Desc.
  ///
  /// In ar, this message translates to:
  /// **'اتعرّف على الحروف'**
  String get level1Desc;

  /// No description provided for @level2Desc.
  ///
  /// In ar, this message translates to:
  /// **'اقرا كلمات قصيرة'**
  String get level2Desc;

  /// No description provided for @level3Desc.
  ///
  /// In ar, this message translates to:
  /// **'اقرا جمل كاملة'**
  String get level3Desc;

  /// No description provided for @yourName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك إيه؟'**
  String get yourName;

  /// No description provided for @nameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك'**
  String get nameHint;

  /// No description provided for @playWith.
  ///
  /// In ar, this message translates to:
  /// **'عايز تلعب مع مين؟'**
  String get playWith;

  /// No description provided for @letsPlay.
  ///
  /// In ar, this message translates to:
  /// **'يلا نلعب!'**
  String get letsPlay;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @gameComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'جاهز يا {name}! اللعبة جاية قريب.'**
  String gameComingSoon(String name);

  /// No description provided for @welcomeName.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً يا {name}!'**
  String welcomeName(String name);

  /// No description provided for @pickGame.
  ///
  /// In ar, this message translates to:
  /// **'اختار لعبة ويلا بينا!'**
  String get pickGame;

  /// No description provided for @gamesComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'ألعاب المستوى ده جاية قريب.'**
  String get gamesComingSoon;

  /// No description provided for @gameFishing.
  ///
  /// In ar, this message translates to:
  /// **'صيد السمك'**
  String get gameFishing;

  /// No description provided for @gameWriteLetter.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الحرف'**
  String get gameWriteLetter;

  /// No description provided for @gameBalloons.
  ///
  /// In ar, this message translates to:
  /// **'امسك البالونة'**
  String get gameBalloons;

  /// No description provided for @gameChallenge.
  ///
  /// In ar, this message translates to:
  /// **'تحدّى {opponent}'**
  String gameChallenge(String opponent);

  /// No description provided for @pickLetter.
  ///
  /// In ar, this message translates to:
  /// **'اختار الحرف اللي هتصطاده!'**
  String get pickLetter;

  /// No description provided for @randomLetter.
  ///
  /// In ar, this message translates to:
  /// **'اختار لي أي حرف'**
  String get randomLetter;

  /// No description provided for @backToGames.
  ///
  /// In ar, this message translates to:
  /// **'الألعاب'**
  String get backToGames;

  /// No description provided for @catchLetter.
  ///
  /// In ar, this message translates to:
  /// **'اصطاد'**
  String get catchLetter;

  /// No description provided for @fishingStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! اصطاد {letter}'**
  String fishingStart(String name, String letter);

  /// No description provided for @fishingCheer1.
  ///
  /// In ar, this message translates to:
  /// **'برافو!'**
  String get fishingCheer1;

  /// No description provided for @fishingCheer2.
  ///
  /// In ar, this message translates to:
  /// **'شاطر يا {name}!'**
  String fishingCheer2(String name);

  /// No description provided for @fishingCheer3.
  ///
  /// In ar, this message translates to:
  /// **'صح كده!'**
  String get fishingCheer3;

  /// No description provided for @fishingCheer4.
  ///
  /// In ar, this message translates to:
  /// **'جامد!'**
  String get fishingCheer4;

  /// Referee after a wrong catch. caught/target are replaced by Coptic letters.
  ///
  /// In ar, this message translates to:
  /// **'لأ! ده {caught} مش {target}'**
  String fishingWrong(String caught, String target);

  /// A fish with the target letter swam away. target is a Coptic letter.
  ///
  /// In ar, this message translates to:
  /// **'فاتك {target}! خلّي عينك عليه'**
  String fishingMissed(String target);

  /// No description provided for @fishingStars3.
  ///
  /// In ar, this message translates to:
  /// **'ممتاز! ولا غلطة!'**
  String get fishingStars3;

  /// No description provided for @fishingStars2.
  ///
  /// In ar, this message translates to:
  /// **'برافو! ركّز شوية وتاخد ٣ نجوم'**
  String get fishingStars2;

  /// No description provided for @fishingStars1.
  ///
  /// In ar, this message translates to:
  /// **'خلصتها! العب تاني عشان تجمع نجوم أكتر'**
  String get fishingStars1;

  /// No description provided for @newBest.
  ///
  /// In ar, this message translates to:
  /// **'رقم جديد!'**
  String get newBest;

  /// No description provided for @playAgain.
  ///
  /// In ar, this message translates to:
  /// **'العب تاني'**
  String get playAgain;

  /// No description provided for @otherLetter.
  ///
  /// In ar, this message translates to:
  /// **'حرف تاني'**
  String get otherLetter;

  /// No description provided for @balloonsPickLetter.
  ///
  /// In ar, this message translates to:
  /// **'اختار الحرف اللي هتمسكه!'**
  String get balloonsPickLetter;

  /// No description provided for @balloonsCatch.
  ///
  /// In ar, this message translates to:
  /// **'هات'**
  String get balloonsCatch;

  /// No description provided for @balloonsStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! هاتلي البالونة اللي عليها {letter}'**
  String balloonsStart(String name, String letter);

  /// No description provided for @balloonsMissed.
  ///
  /// In ar, this message translates to:
  /// **'بالونة {target} طارت! خلّي عينك عليها'**
  String balloonsMissed(String target);

  /// No description provided for @writingPickLetter.
  ///
  /// In ar, this message translates to:
  /// **'اختار الحرف اللي هتكتبه!'**
  String get writingPickLetter;

  /// No description provided for @writingStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! لوّن الحرف بالطباشير'**
  String writingStart(String name);

  /// No description provided for @writingWatch.
  ///
  /// In ar, this message translates to:
  /// **'بص الأول بيتكتب ازاي'**
  String get writingWatch;

  /// No description provided for @writingHalfway.
  ///
  /// In ar, this message translates to:
  /// **'نص الحرف خلص! كمّل'**
  String get writingHalfway;

  /// No description provided for @writingWarn.
  ///
  /// In ar, this message translates to:
  /// **'حاسب! خلّيك جوّه الحرف'**
  String get writingWarn;

  /// No description provided for @writingWipe.
  ///
  /// In ar, this message translates to:
  /// **'اتلخبطت شوية! هامسحها ونبدأ تاني'**
  String get writingWipe;

  /// No description provided for @writingCapitalNext.
  ///
  /// In ar, this message translates to:
  /// **'برافو! يلا نكتب الحرف الكبير'**
  String get writingCapitalNext;

  /// No description provided for @writingSmall.
  ///
  /// In ar, this message translates to:
  /// **'صغير'**
  String get writingSmall;

  /// No description provided for @writingCapital.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get writingCapital;

  /// No description provided for @writingFilled.
  ///
  /// In ar, this message translates to:
  /// **'اللي اتلوّن'**
  String get writingFilled;

  /// No description provided for @writingMess.
  ///
  /// In ar, this message translates to:
  /// **'اللخبطة برّه الحرف'**
  String get writingMess;

  /// No description provided for @writingWipesLeft.
  ///
  /// In ar, this message translates to:
  /// **'مرات المسح الباقية'**
  String get writingWipesLeft;

  /// No description provided for @writingThin.
  ///
  /// In ar, this message translates to:
  /// **'رفيع'**
  String get writingThin;

  /// No description provided for @writingMedium.
  ///
  /// In ar, this message translates to:
  /// **'وسط'**
  String get writingMedium;

  /// No description provided for @writingThick.
  ///
  /// In ar, this message translates to:
  /// **'تخين'**
  String get writingThick;

  /// No description provided for @writingPassed.
  ///
  /// In ar, this message translates to:
  /// **'كتبته!'**
  String get writingPassed;

  /// No description provided for @writingPassedBody.
  ///
  /// In ar, this message translates to:
  /// **'الحرف الصغير والكبير، بخط إيدك'**
  String get writingPassedBody;

  /// No description provided for @writingFailed.
  ///
  /// In ar, this message translates to:
  /// **'يلا نجرب تاني!'**
  String get writingFailed;

  /// No description provided for @writingFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'السبورة اتمسحت {count} مرات. خلّي الطباشير جوّه الحرف'**
  String writingFailedBody(int count);

  /// No description provided for @writingAgain.
  ///
  /// In ar, this message translates to:
  /// **'اكتبه تاني'**
  String get writingAgain;

  /// No description provided for @writingShare.
  ///
  /// In ar, this message translates to:
  /// **'شارك الرسمة'**
  String get writingShare;

  /// No description provided for @writingShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'برافو يا {name}! كتبت حرف {letter}'**
  String writingShareTitle(String name, String letter);

  /// No description provided for @writingShareWith.
  ///
  /// In ar, this message translates to:
  /// **'مع {hero} على سبورة جدو'**
  String writingShareWith(String hero);

  /// No description provided for @writingShareText.
  ///
  /// In ar, this message translates to:
  /// **'برافو يا {name}! كتبت الحرف القبطي {letter} في نونو وفوفو'**
  String writingShareText(String name, String letter);

  /// No description provided for @writingEraser.
  ///
  /// In ar, this message translates to:
  /// **'أستيكة'**
  String get writingEraser;
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

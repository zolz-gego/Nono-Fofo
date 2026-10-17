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

  /// No description provided for @writingShareSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت الصورة في التنزيلات'**
  String get writingShareSaved;

  /// No description provided for @writingFullScreen.
  ///
  /// In ar, this message translates to:
  /// **'كبّر السبورة'**
  String get writingFullScreen;

  /// No description provided for @writingExitFullScreen.
  ///
  /// In ar, this message translates to:
  /// **'رجّع السبورة زي ما كانت'**
  String get writingExitFullScreen;

  /// No description provided for @gameCards.
  ///
  /// In ar, this message translates to:
  /// **'كروت جدو'**
  String get gameCards;

  /// No description provided for @cardsPickLevel.
  ///
  /// In ar, this message translates to:
  /// **'هتلعب بكام كارت؟'**
  String get cardsPickLevel;

  /// No description provided for @cardsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{{count} كروت} other{{count} كارت}}'**
  String cardsCount(int count);

  /// No description provided for @cardsBest.
  ///
  /// In ar, this message translates to:
  /// **'أحسن وقت {time} · {moves} حركة'**
  String cardsBest(String time, int moves);

  /// No description provided for @cardsStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! دوّر على كل حرف كبير وصغيره'**
  String cardsStart(String name);

  /// No description provided for @cardsTime.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get cardsTime;

  /// No description provided for @cardsMoves.
  ///
  /// In ar, this message translates to:
  /// **'الحركات'**
  String get cardsMoves;

  /// No description provided for @cardsPairs.
  ///
  /// In ar, this message translates to:
  /// **'الأزواج'**
  String get cardsPairs;

  /// No description provided for @cardsSolved.
  ///
  /// In ar, this message translates to:
  /// **'خلّصت الكروت!'**
  String get cardsSolved;

  /// No description provided for @cardsSolvedBody.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{لقيت كل الأزواج في {count} كروت} other{لقيت كل الأزواج في {count} كارت}}'**
  String cardsSolvedBody(int count);

  /// No description provided for @cardsNewRecord.
  ///
  /// In ar, this message translates to:
  /// **'رقم قياسي جديد!'**
  String get cardsNewRecord;

  /// No description provided for @cardsOtherLevel.
  ///
  /// In ar, this message translates to:
  /// **'عدد كروت تاني'**
  String get cardsOtherLevel;

  /// No description provided for @cardsShare.
  ///
  /// In ar, this message translates to:
  /// **'شارك وقتك'**
  String get cardsShare;

  /// No description provided for @cardsShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{برافو يا {name}! خلّصت {count} كروت} other{برافو يا {name}! خلّصت {count} كارت}}'**
  String cardsShareTitle(String name, int count);

  /// No description provided for @cardsShareWith.
  ///
  /// In ar, this message translates to:
  /// **'مع {hero} على بحر إسكندرية'**
  String cardsShareWith(String hero);

  /// No description provided for @cardsShareText.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{برافو يا {name}! خلّصت {count} كروت في كروت جدو في {time} و{moves} حركة، في نونو وفوفو} other{برافو يا {name}! خلّصت {count} كارت في كروت جدو في {time} و{moves} حركة، في نونو وفوفو}}'**
  String cardsShareText(String name, int count, String time, int moves);

  /// No description provided for @gameMonastery.
  ///
  /// In ar, this message translates to:
  /// **'دوّر في الدير'**
  String get gameMonastery;

  /// No description provided for @monasteryPickLevel.
  ///
  /// In ar, this message translates to:
  /// **'هتدوّر على كام حرف؟'**
  String get monasteryPickLevel;

  /// No description provided for @monasteryCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{{count} حروف} other{{count} حرف}}'**
  String monasteryCount(int count);

  /// No description provided for @monasteryBest.
  ///
  /// In ar, this message translates to:
  /// **'أحسن وقت {time} · غلط {wrong}'**
  String monasteryBest(String time, int wrong);

  /// No description provided for @monasteryStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! الحروف مستخبية في الدير، دوّر عليها'**
  String monasteryStart(String name);

  /// No description provided for @monasteryFound.
  ///
  /// In ar, this message translates to:
  /// **'لقيت'**
  String get monasteryFound;

  /// No description provided for @monasteryWrong.
  ///
  /// In ar, this message translates to:
  /// **'مش هنا!'**
  String get monasteryWrong;

  /// No description provided for @monasteryHint.
  ///
  /// In ar, this message translates to:
  /// **'مساعدة'**
  String get monasteryHint;

  /// No description provided for @monasteryHintSay.
  ///
  /// In ar, this message translates to:
  /// **'بص هنا كده!'**
  String get monasteryHintSay;

  /// No description provided for @monasteryMisses.
  ///
  /// In ar, this message translates to:
  /// **'غلط'**
  String get monasteryMisses;

  /// No description provided for @monasteryHints.
  ///
  /// In ar, this message translates to:
  /// **'مساعدات'**
  String get monasteryHints;

  /// No description provided for @monasterySolved.
  ///
  /// In ar, this message translates to:
  /// **'لقيت كل الحروف!'**
  String get monasterySolved;

  /// No description provided for @monasterySolvedBody.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{لقيت {count} حروف مستخبية في الدير} other{لقيت {count} حرف مستخبي في الدير}}'**
  String monasterySolvedBody(int count);

  /// No description provided for @monasteryOtherLevel.
  ///
  /// In ar, this message translates to:
  /// **'عدد حروف تاني'**
  String get monasteryOtherLevel;

  /// No description provided for @monasteryShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{برافو يا {name}! لقيت {count} حروف} other{برافو يا {name}! لقيت {count} حرف}}'**
  String monasteryShareTitle(String name, int count);

  /// No description provided for @monasteryShareWith.
  ///
  /// In ar, this message translates to:
  /// **'مع {hero} في دير الصحرا'**
  String monasteryShareWith(String hero);

  /// No description provided for @monasteryShareText.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{برافو يا {name}! لقيت {count} حروف مستخبية في دوّر في الدير في {time}، في نونو وفوفو} other{برافو يا {name}! لقيت {count} حرف مستخبي في دوّر في الدير في {time}، في نونو وفوفو}}'**
  String monasteryShareText(String name, int count, String time);

  /// No description provided for @gameSnakes.
  ///
  /// In ar, this message translates to:
  /// **'السلم والتعبان'**
  String get gameSnakes;

  /// No description provided for @snakesPickMode.
  ///
  /// In ar, this message translates to:
  /// **'عايز تلعب إزاي؟'**
  String get snakesPickMode;

  /// No description provided for @snakesVsComputer.
  ///
  /// In ar, this message translates to:
  /// **'العب ضد {opponent}'**
  String snakesVsComputer(String opponent);

  /// No description provided for @snakesVsComputerBody.
  ///
  /// In ar, this message translates to:
  /// **'{opponent} بيرمي الزهر لوحده'**
  String snakesVsComputerBody(String opponent);

  /// No description provided for @snakesWithFriend.
  ///
  /// In ar, this message translates to:
  /// **'العب مع صاحبك'**
  String get snakesWithFriend;

  /// No description provided for @snakesWithFriendBody.
  ///
  /// In ar, this message translates to:
  /// **'اتبادلوا الأدوار على نفس الجهاز'**
  String get snakesWithFriendBody;

  /// No description provided for @snakesFriendName.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحبك'**
  String get snakesFriendName;

  /// No description provided for @snakesFriendPlaysAs.
  ///
  /// In ar, this message translates to:
  /// **'صاحبك هيلعب بقطعة {hero}'**
  String snakesFriendPlaysAs(String hero);

  /// No description provided for @snakesStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا {name}! جاوب صح عشان ترمي الزهر'**
  String snakesStart(String name);

  /// No description provided for @snakesTurn.
  ///
  /// In ar, this message translates to:
  /// **'دور {name}'**
  String snakesTurn(String name);

  /// No description provided for @snakesWhatName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الحرف ده إيه؟'**
  String get snakesWhatName;

  /// No description provided for @snakesWhichLetter.
  ///
  /// In ar, this message translates to:
  /// **'فين حرف {name}؟'**
  String snakesWhichLetter(String name);

  /// No description provided for @snakesTapDice.
  ///
  /// In ar, this message translates to:
  /// **'دوس على الزهر!'**
  String get snakesTapDice;

  /// No description provided for @snakesCorrect.
  ///
  /// In ar, this message translates to:
  /// **'صح! ارمي الزهر'**
  String get snakesCorrect;

  /// No description provided for @snakesWrong.
  ///
  /// In ar, this message translates to:
  /// **'أوبس! الدور راح'**
  String get snakesWrong;

  /// No description provided for @snakesOvershoot.
  ///
  /// In ar, this message translates to:
  /// **'كتير! محتاج {count} بالظبط'**
  String snakesOvershoot(int count);

  /// No description provided for @snakesLadder.
  ///
  /// In ar, this message translates to:
  /// **'اطلع السلم!'**
  String get snakesLadder;

  /// No description provided for @snakesSnake.
  ///
  /// In ar, this message translates to:
  /// **'يا خبر، تعبان!'**
  String get snakesSnake;

  /// No description provided for @snakesComputerThinks.
  ///
  /// In ar, this message translates to:
  /// **'دوري أنا!'**
  String get snakesComputerThinks;

  /// No description provided for @snakesWinner.
  ///
  /// In ar, this message translates to:
  /// **'{name} كسب!'**
  String snakesWinner(String name);

  /// No description provided for @snakesYouWon.
  ///
  /// In ar, this message translates to:
  /// **'كسبت!'**
  String get snakesYouWon;

  /// No description provided for @snakesYouWonBody.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للمربع {count} قبل {opponent}'**
  String snakesYouWonBody(int count, String opponent);

  /// No description provided for @snakesYouLost.
  ///
  /// In ar, this message translates to:
  /// **'{name} كسب المرة دي!'**
  String snakesYouLost(String name);

  /// No description provided for @snakesYouLostBody.
  ///
  /// In ar, this message translates to:
  /// **'كل ما تجاوب صح أكتر، ترمي الزهر أكتر. جرب تاني!'**
  String get snakesYouLostBody;

  /// No description provided for @snakesFriendWonBody.
  ///
  /// In ar, this message translates to:
  /// **'{name} وصل للمربع {count} الأول'**
  String snakesFriendWonBody(String name, int count);

  /// No description provided for @snakesChallengeDone.
  ///
  /// In ar, this message translates to:
  /// **'خلّصت التحدي!'**
  String get snakesChallengeDone;

  /// No description provided for @snakesRight.
  ///
  /// In ar, this message translates to:
  /// **'إجابات صح'**
  String get snakesRight;

  /// No description provided for @snakesRolls.
  ///
  /// In ar, this message translates to:
  /// **'رميات'**
  String get snakesRolls;

  /// No description provided for @snakesChangePlayers.
  ///
  /// In ar, this message translates to:
  /// **'غيّر اللاعبين'**
  String get snakesChangePlayers;

  /// No description provided for @snakesShare.
  ///
  /// In ar, this message translates to:
  /// **'شارك'**
  String get snakesShare;

  /// No description provided for @snakesShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'{name} كسب السلم والتعبان!'**
  String snakesShareTitle(String name);

  /// No description provided for @snakesShareVs.
  ///
  /// In ar, this message translates to:
  /// **'{winner} غلب {loser}'**
  String snakesShareVs(String winner, String loser);

  /// No description provided for @snakesShareWith.
  ///
  /// In ar, this message translates to:
  /// **'مع {hero} عند الأهرامات'**
  String snakesShareWith(String hero);

  /// No description provided for @snakesShareText.
  ///
  /// In ar, this message translates to:
  /// **'{name} كسب السلم والتعبان في نونو وفوفو، وجاوب {correct} من {asked} حروف صح!'**
  String snakesShareText(String name, int correct, int asked);
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

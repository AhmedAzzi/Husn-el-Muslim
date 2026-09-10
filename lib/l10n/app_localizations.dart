import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'حصن المسلم'**
  String get appTitle;

  /// No description provided for @navAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get navAdhkar;

  /// No description provided for @navDua.
  ///
  /// In ar, this message translates to:
  /// **'دعاء'**
  String get navDua;

  /// No description provided for @navNames.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get navNames;

  /// No description provided for @navRuqyah.
  ///
  /// In ar, this message translates to:
  /// **'الرقية الشرعية'**
  String get navRuqyah;

  /// No description provided for @navMasbaha.
  ///
  /// In ar, this message translates to:
  /// **'مسبحة'**
  String get navMasbaha;

  /// No description provided for @navPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get navPrayerTimes;

  /// No description provided for @navMosqueMap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المساجد'**
  String get navMosqueMap;

  /// No description provided for @navQibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get navQibla;

  /// No description provided for @navFajrLog.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الصلوات'**
  String get navFajrLog;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @trackCurrent.
  ///
  /// In ar, this message translates to:
  /// **'السلسلة الحالية'**
  String get trackCurrent;

  /// No description provided for @trackLongest.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get trackLongest;

  /// No description provided for @trackToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get trackToday;

  /// No description provided for @trackDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one {{count} يوم} two {{count} يومان} other {{count} أيام}}'**
  String trackDays(int count);

  /// No description provided for @qiblaTitle.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qiblaTitle;

  /// No description provided for @qiblaNorth.
  ///
  /// In ar, this message translates to:
  /// **'ش'**
  String get qiblaNorth;

  /// No description provided for @qiblaBearing.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة: {deg}°'**
  String qiblaBearing(String deg);

  /// No description provided for @qiblaDistance.
  ///
  /// In ar, this message translates to:
  /// **'المسافة إلى الكعبة: {km} كم'**
  String qiblaDistance(String km);

  /// No description provided for @qiblaFacing.
  ///
  /// In ar, this message translates to:
  /// **'أنت متجه نحو القبلة ✓'**
  String get qiblaFacing;

  /// No description provided for @qiblaTurn.
  ///
  /// In ar, this message translates to:
  /// **'استدر {deg}° {direction}'**
  String qiblaTurn(String deg, String direction);

  /// No description provided for @qiblaRight.
  ///
  /// In ar, this message translates to:
  /// **'يميناً'**
  String get qiblaRight;

  /// No description provided for @qiblaLeft.
  ///
  /// In ar, this message translates to:
  /// **'يساراً'**
  String get qiblaLeft;

  /// No description provided for @qiblaCalibrate.
  ///
  /// In ar, this message translates to:
  /// **'حرّك الهاتف على شكل 8 لمعايرة البوصلة عند وجود تداخل مغناطيسي. يعمل دون إنترنت.'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get qiblaRetry;

  /// No description provided for @qiblaNoLocation.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديد الموقع — فعّل GPS أو حدد موقع الصلاة أولاً'**
  String get qiblaNoLocation;

  /// No description provided for @qiblaNoSensor.
  ///
  /// In ar, this message translates to:
  /// **'البوصلة غير متاحة على هذا الجهاز — اتجاه القبلة محسوب أدناه بدون بوصلة حية'**
  String get qiblaNoSensor;

  /// No description provided for @awakeTitle.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت مستيقظ؟'**
  String get awakeTitle;

  /// No description provided for @awakeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أكملت التحدي — أكّد استيقاظك لتسجيل الفجر'**
  String get awakeSubtitle;

  /// No description provided for @iAmAwake.
  ///
  /// In ar, this message translates to:
  /// **'أنا مستيقظ'**
  String get iAmAwake;

  /// No description provided for @wellDone.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت'**
  String get wellDone;

  /// No description provided for @wokeForFajr.
  ///
  /// In ar, this message translates to:
  /// **'لقد استيقظت لصلاة الفجر'**
  String get wokeForFajr;

  /// No description provided for @continueBtn.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueBtn;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لغة واجهة التطبيق'**
  String get settingsLanguageSubtitle;

  /// No description provided for @langArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langFrench.
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @diagTitle.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص المتقدم'**
  String get diagTitle;

  /// No description provided for @diagPermissions.
  ///
  /// In ar, this message translates to:
  /// **'حالة الأذونات'**
  String get diagPermissions;

  /// No description provided for @diagExactTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنبهات الدقيقة'**
  String get diagExactTitle;

  /// No description provided for @diagExactOk.
  ///
  /// In ar, this message translates to:
  /// **'مسموح — منبه الفجر يعمل بدقة'**
  String get diagExactOk;

  /// No description provided for @diagExactDenied.
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح — المنبهات قد لا ترن في وقتها'**
  String get diagExactDenied;

  /// No description provided for @diagOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get diagOpenSettings;

  /// No description provided for @diagBatteryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحسين البطارية'**
  String get diagBatteryTitle;

  /// No description provided for @diagBatteryOn.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل — قد يوقف النظام المنبهات'**
  String get diagBatteryOn;

  /// No description provided for @diagBatteryOff.
  ///
  /// In ar, this message translates to:
  /// **'مستثنى — التطبيق يعمل بحرية'**
  String get diagBatteryOff;

  /// No description provided for @diagRequestExemption.
  ///
  /// In ar, this message translates to:
  /// **'طلب الاستثناء'**
  String get diagRequestExemption;

  /// No description provided for @diagOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'الظهور فوق التطبيقات'**
  String get diagOverlayTitle;

  /// No description provided for @diagOverlayOk.
  ///
  /// In ar, this message translates to:
  /// **'ممنوح — النوافذ العائمة تعمل'**
  String get diagOverlayOk;

  /// No description provided for @diagOverlayDenied.
  ///
  /// In ar, this message translates to:
  /// **'غير ممنوح — التنبيهات العائمة معطلة'**
  String get diagOverlayDenied;

  /// No description provided for @diagRequestPermission.
  ///
  /// In ar, this message translates to:
  /// **'طلب الإذن'**
  String get diagRequestPermission;

  /// No description provided for @diagScheduled.
  ///
  /// In ar, this message translates to:
  /// **'المنبهات المجدولة'**
  String get diagScheduled;

  /// No description provided for @diagReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة التشخيص'**
  String get diagReadFailed;

  /// No description provided for @diagRescheduleAll.
  ///
  /// In ar, this message translates to:
  /// **'إعادة جدولة كل المنبهات'**
  String get diagRescheduleAll;

  /// No description provided for @diagRescheduled.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة جدولة كل المنبهات'**
  String get diagRescheduled;

  /// No description provided for @diagRescheduleFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت إعادة الجدولة'**
  String get diagRescheduleFailed;

  /// No description provided for @diagTracking.
  ///
  /// In ar, this message translates to:
  /// **'التتبع'**
  String get diagTracking;

  /// No description provided for @diagCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get diagCurrent;

  /// No description provided for @diagLongest.
  ///
  /// In ar, this message translates to:
  /// **'الأطول'**
  String get diagLongest;

  /// No description provided for @diagTest.
  ///
  /// In ar, this message translates to:
  /// **'اختبار'**
  String get diagTest;

  /// No description provided for @diagTestDesc.
  ///
  /// In ar, this message translates to:
  /// **'يجدول منبه تحدي الفجر الحقيقي بعد 5 ثوانٍ (صوت + إشعار + شاشة التحدي).'**
  String get diagTestDesc;

  /// No description provided for @diagTestScheduling.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الجدولة…'**
  String get diagTestScheduling;

  /// No description provided for @diagTestButton.
  ///
  /// In ar, this message translates to:
  /// **'تجربة منبه الفجر (5 ثوانٍ)'**
  String get diagTestButton;

  /// No description provided for @diagTestWillRing.
  ///
  /// In ar, this message translates to:
  /// **'سيرن منبه التجربة بعد 5 ثوانٍ'**
  String get diagTestWillRing;

  /// No description provided for @diagTestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جدولة التجربة — تحقق من إذن المنبهات الدقيقة'**
  String get diagTestFailed;

  /// No description provided for @chTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحدي صلاة الفجر'**
  String get chTitle;

  /// No description provided for @chAnswerToStop.
  ///
  /// In ar, this message translates to:
  /// **'أجب عن السؤال لإيقاف المنبه'**
  String get chAnswerToStop;

  /// No description provided for @chRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي: {count}'**
  String chRemaining(int count);

  /// No description provided for @chWriteCategory.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الفئة التي ينتمي إليها هذا الذكر:'**
  String get chWriteCategory;

  /// No description provided for @chWriteAnswerHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الإجابة هنا'**
  String get chWriteAnswerHint;

  /// No description provided for @chVerifyAnswer.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الإجابة'**
  String get chVerifyAnswer;

  /// No description provided for @chWrongAnswer.
  ///
  /// In ar, this message translates to:
  /// **'إجابة خاطئة'**
  String get chWrongAnswer;

  /// No description provided for @chTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get chTryAgain;

  /// No description provided for @chLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل الأسئلة'**
  String get chLoadError;

  /// No description provided for @chMathSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حل المسألة لإيقاف المنبه'**
  String get chMathSubtitle;

  /// No description provided for @chMathHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الإجابة بالأرقام'**
  String get chMathHint;

  /// No description provided for @chMemoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحدي الذاكرة'**
  String get chMemoryTitle;

  /// No description provided for @chMemorySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقلب البطاقات وطابق الأزواج الأربعة'**
  String get chMemorySubtitle;

  /// No description provided for @chMatched.
  ///
  /// In ar, this message translates to:
  /// **'المطابق: {done} / {total}'**
  String chMatched(int done, int total);

  /// No description provided for @chShakeTitle.
  ///
  /// In ar, this message translates to:
  /// **'هز الهاتف للاستيقاظ'**
  String get chShakeTitle;

  /// No description provided for @chShakeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'هز الهاتف بقوة حتى يمتلئ الشريط'**
  String get chShakeSubtitle;

  /// No description provided for @chSensorUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'حساس الحركة غير متاح على هذا الجهاز'**
  String get chSensorUnavailable;

  /// No description provided for @chSwitchToQuestions.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى تحدي الأسئلة'**
  String get chSwitchToQuestions;

  /// No description provided for @chCardHidden.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة مقلوبة {n}'**
  String chCardHidden(int n);

  /// No description provided for @chCardShown.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة {face}'**
  String chCardShown(String face);

  /// No description provided for @chPreviewBanner.
  ///
  /// In ar, this message translates to:
  /// **'معاينة — لن يتم تسجيل أي شيء'**
  String get chPreviewBanner;

  /// No description provided for @sheetExactTitle.
  ///
  /// In ar, this message translates to:
  /// **'إذن المنبهات الدقيقة مطلوب'**
  String get sheetExactTitle;

  /// No description provided for @sheetExactBody.
  ///
  /// In ar, this message translates to:
  /// **'بدون إذن المنبهات والتذكيرات من إعدادات النظام لن يرن منبه تحدي الفجر في موعده. هل تريد فتح الإعدادات لمنحه الآن؟'**
  String get sheetExactBody;

  /// No description provided for @sheetLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get sheetLater;

  /// No description provided for @sheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحدي الاستيقاظ لصلاة الفجر'**
  String get sheetTitle;

  /// No description provided for @sheetSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'منبه تفاعلي ذكي لا يتوقف إلا بعد حل الأسئلة'**
  String get sheetSubtitle;

  /// No description provided for @sheetEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المنبه التفاعلي'**
  String get sheetEnable;

  /// No description provided for @sheetEnabledOn.
  ///
  /// In ar, this message translates to:
  /// **'المنبه مفعل وسيرن في الموعد المحدد'**
  String get sheetEnabledOn;

  /// No description provided for @sheetEnabledOff.
  ///
  /// In ar, this message translates to:
  /// **'المنبه متوقف حالياً'**
  String get sheetEnabledOff;

  /// No description provided for @sheetWarnTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه'**
  String get sheetWarnTitle;

  /// No description provided for @sheetWarnBody.
  ///
  /// In ar, this message translates to:
  /// **'تم التفعيل، لكن المنبه لن يرن قبل منح إذن المنبهات الدقيقة'**
  String get sheetWarnBody;

  /// No description provided for @sheetRingTime.
  ///
  /// In ar, this message translates to:
  /// **'موعد رنين المنبه'**
  String get sheetRingTime;

  /// No description provided for @sheetLastThird.
  ///
  /// In ar, this message translates to:
  /// **'الثلث الأخير'**
  String get sheetLastThird;

  /// No description provided for @sheetLastThirdSub.
  ///
  /// In ar, this message translates to:
  /// **'تلقائياً لقيام الليل'**
  String get sheetLastThirdSub;

  /// No description provided for @sheetCustom.
  ///
  /// In ar, this message translates to:
  /// **'وقت مخصص'**
  String get sheetCustom;

  /// No description provided for @sheetCustomSub.
  ///
  /// In ar, this message translates to:
  /// **'دقائق محددة قبل الفجر'**
  String get sheetCustomSub;

  /// No description provided for @sheetBeforeFajrBy.
  ///
  /// In ar, this message translates to:
  /// **'الرنين قبل أذان الفجر بـ:'**
  String get sheetBeforeFajrBy;

  /// No description provided for @sheetMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one {{count} دقيقة} two {{count} دقيقتان} other {{count} دقائق}}'**
  String sheetMinutes(int count);

  /// No description provided for @sheetQuestionCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد أسئلة التحدي'**
  String get sheetQuestionCount;

  /// No description provided for @sheetQuestions.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one {{count} سؤال} two {{count} سؤالان} other {{count} أسئلة}}'**
  String sheetQuestions(int count);

  /// No description provided for @sheetTextMode.
  ///
  /// In ar, this message translates to:
  /// **'كتابة الإجابة نصياً'**
  String get sheetTextMode;

  /// No description provided for @sheetTextModeSub.
  ///
  /// In ar, this message translates to:
  /// **'زيادة مستوى التحدي بالكتابة بدلاً من الاختيار من متعدد'**
  String get sheetTextModeSub;

  /// No description provided for @sheetTestAt.
  ///
  /// In ar, this message translates to:
  /// **'موعد اختبار الرنين:'**
  String get sheetTestAt;

  /// No description provided for @sheetSeconds.
  ///
  /// In ar, this message translates to:
  /// **'{count} ث'**
  String sheetSeconds(int count);

  /// No description provided for @sheetTestScheduled.
  ///
  /// In ar, this message translates to:
  /// **'تم جدولة اختبار المنبه'**
  String get sheetTestScheduled;

  /// No description provided for @sheetTestWillRing.
  ///
  /// In ar, this message translates to:
  /// **'سيرن منبه تحدي الفجر فعلياً خلال {seconds} ثوانٍ'**
  String sheetTestWillRing(int seconds);

  /// No description provided for @sheetTestFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جدولة الاختبار'**
  String get sheetTestFailedTitle;

  /// No description provided for @sheetTestFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من منح إذن المنبهات الدقيقة في إعدادات النظام'**
  String get sheetTestFailedBody;

  /// No description provided for @sheetTestButton.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الرنين الفعلي (المنبه الحقيقي)'**
  String get sheetTestButton;

  /// No description provided for @nsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التنبيهات والأذان'**
  String get nsTitle;

  /// No description provided for @nsBatteryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحسين البطارية مفعل في النظام'**
  String get nsBatteryTitle;

  /// No description provided for @nsBatteryBody.
  ///
  /// In ar, this message translates to:
  /// **'قد يُوقف النظام إشعارات الأذان والعد التنازلي التلقائي لتوفير الطاقة. يوصى باستثناء التطبيق من تحسين البطارية لضمان دقة التنبيهات.'**
  String get nsBatteryBody;

  /// No description provided for @nsBatteryButton.
  ///
  /// In ar, this message translates to:
  /// **'استثناء التطبيق من تحسين البطارية'**
  String get nsBatteryButton;

  /// No description provided for @nsPersistentSection.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات النظام الدائمة'**
  String get nsPersistentSection;

  /// No description provided for @nsPersistent.
  ///
  /// In ar, this message translates to:
  /// **'إشعار شريط الحالة الدائم'**
  String get nsPersistent;

  /// No description provided for @nsPersistentSub.
  ///
  /// In ar, this message translates to:
  /// **'عرض التاريخ الهجري وموعد الصلاة القادمة دائماً'**
  String get nsPersistentSub;

  /// No description provided for @nsFajrEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل منبه تحدي الفجر'**
  String get nsFajrEnable;

  /// No description provided for @nsFajrEnableSub.
  ///
  /// In ar, this message translates to:
  /// **'منبه تفاعلي ذكي لا يتوقف إلا بعد حل أسئلة'**
  String get nsFajrEnableSub;

  /// No description provided for @nsChallengeType.
  ///
  /// In ar, this message translates to:
  /// **'نوع التحدي'**
  String get nsChallengeType;

  /// No description provided for @nsTypeQuestions.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة'**
  String get nsTypeQuestions;

  /// No description provided for @nsTypeQuestionsSub.
  ///
  /// In ar, this message translates to:
  /// **'أذكار وأدعية'**
  String get nsTypeQuestionsSub;

  /// No description provided for @nsTypeMath.
  ///
  /// In ar, this message translates to:
  /// **'رياضيات'**
  String get nsTypeMath;

  /// No description provided for @nsTypeMathSub.
  ///
  /// In ar, this message translates to:
  /// **'حساب ذهني'**
  String get nsTypeMathSub;

  /// No description provided for @nsTypeMemory.
  ///
  /// In ar, this message translates to:
  /// **'ذاكرة'**
  String get nsTypeMemory;

  /// No description provided for @nsTypeMemorySub.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة البطاقات'**
  String get nsTypeMemorySub;

  /// No description provided for @nsTypeShake.
  ///
  /// In ar, this message translates to:
  /// **'هز'**
  String get nsTypeShake;

  /// No description provided for @nsTypeShakeSub.
  ///
  /// In ar, this message translates to:
  /// **'هز الهاتف'**
  String get nsTypeShakeSub;

  /// No description provided for @nsTypeRandom.
  ///
  /// In ar, this message translates to:
  /// **'عشوائي'**
  String get nsTypeRandom;

  /// No description provided for @nsTypeRandomSub.
  ///
  /// In ar, this message translates to:
  /// **'نوع مفاجئ'**
  String get nsTypeRandomSub;

  /// No description provided for @nsRandomPool.
  ///
  /// In ar, this message translates to:
  /// **'الأنواع المشمولة في العشوائي'**
  String get nsRandomPool;

  /// No description provided for @nsShakeSensitivity.
  ///
  /// In ar, this message translates to:
  /// **'حساسية الهز'**
  String get nsShakeSensitivity;

  /// No description provided for @nsLow.
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get nsLow;

  /// No description provided for @nsShakeMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get nsShakeMedium;

  /// No description provided for @nsHigh.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get nsHigh;

  /// No description provided for @nsDifficulty.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الصعوبة'**
  String get nsDifficulty;

  /// No description provided for @nsEasy.
  ///
  /// In ar, this message translates to:
  /// **'سهل'**
  String get nsEasy;

  /// No description provided for @nsDiffMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get nsDiffMedium;

  /// No description provided for @nsHard.
  ///
  /// In ar, this message translates to:
  /// **'صعب'**
  String get nsHard;

  /// No description provided for @nsHardSub.
  ///
  /// In ar, this message translates to:
  /// **'كتابة إجبارية'**
  String get nsHardSub;

  /// No description provided for @nsWakeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاستيقاظ'**
  String get nsWakeConfirm;

  /// No description provided for @nsWakeConfirmSub.
  ///
  /// In ar, this message translates to:
  /// **'بعد التحدي: هل أنت مستيقظ؟ ثم تسجيل النجاح'**
  String get nsWakeConfirmSub;

  /// No description provided for @nsTryNow.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التحدي الآن'**
  String get nsTryNow;

  /// No description provided for @nsOpenLog.
  ///
  /// In ar, this message translates to:
  /// **'سجل الفجر والتقدم'**
  String get nsOpenLog;

  /// No description provided for @nsAlarmSound.
  ///
  /// In ar, this message translates to:
  /// **'صوت المنبه'**
  String get nsAlarmSound;

  /// No description provided for @nsSoundAdhan.
  ///
  /// In ar, this message translates to:
  /// **'الأذان'**
  String get nsSoundAdhan;

  /// No description provided for @nsSoundAdhanSub.
  ///
  /// In ar, this message translates to:
  /// **'المرفق مع التطبيق'**
  String get nsSoundAdhanSub;

  /// No description provided for @nsSoundSystem.
  ///
  /// In ar, this message translates to:
  /// **'نغمة النظام'**
  String get nsSoundSystem;

  /// No description provided for @nsSoundSystemSub.
  ///
  /// In ar, this message translates to:
  /// **'نغمة منبه الهاتف'**
  String get nsSoundSystemSub;

  /// No description provided for @nsSoundCustom.
  ///
  /// In ar, this message translates to:
  /// **'ملف مخصص'**
  String get nsSoundCustom;

  /// No description provided for @nsSoundCustomSub.
  ///
  /// In ar, this message translates to:
  /// **'ملف صوتي من جهازك'**
  String get nsSoundCustomSub;

  /// No description provided for @nsPickAudio.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف صوتي'**
  String get nsPickAudio;

  /// No description provided for @nsChangeAudio.
  ///
  /// In ar, this message translates to:
  /// **'تم الاختيار — تغيير الملف'**
  String get nsChangeAudio;

  /// No description provided for @nsPreviewSound.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الصوت'**
  String get nsPreviewSound;

  /// No description provided for @nsPreviewPlaying.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل معاينة الصوت…'**
  String get nsPreviewPlaying;

  /// No description provided for @nsStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get nsStop;

  /// No description provided for @nsAlarmVolume.
  ///
  /// In ar, this message translates to:
  /// **'مستوى صوت المنبه'**
  String get nsAlarmVolume;

  /// No description provided for @nsAlarmVibrate.
  ///
  /// In ar, this message translates to:
  /// **'الاهتزاز أثناء الرنين'**
  String get nsAlarmVibrate;

  /// No description provided for @nsAlarmLoop.
  ///
  /// In ar, this message translates to:
  /// **'تكرار الصوت حتى الإيقاف'**
  String get nsAlarmLoop;

  /// No description provided for @nsGentleWake.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ اللطيف (تدرج الصوت)'**
  String get nsGentleWake;

  /// No description provided for @nsInstant.
  ///
  /// In ar, this message translates to:
  /// **'فوري'**
  String get nsInstant;

  /// No description provided for @nsExtraAlarms.
  ///
  /// In ar, this message translates to:
  /// **'منبهات إضافية'**
  String get nsExtraAlarms;

  /// No description provided for @nsSuhoor.
  ///
  /// In ar, this message translates to:
  /// **'منبه السحور'**
  String get nsSuhoor;

  /// No description provided for @nsSuhoorSub.
  ///
  /// In ar, this message translates to:
  /// **'وقت السحور قبل الفجر (مستقل عن أذان الفجر)'**
  String get nsSuhoorSub;

  /// No description provided for @nsBeforeFajrBy.
  ///
  /// In ar, this message translates to:
  /// **'قبل الفجر بـ:'**
  String get nsBeforeFajrBy;

  /// No description provided for @nsPreFajr.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه قبل الفجر'**
  String get nsPreFajr;

  /// No description provided for @nsPreFajrSub.
  ///
  /// In ar, this message translates to:
  /// **'تحذير لطيف قبل الأذان (5 / 10 / 15 دقيقة)'**
  String get nsPreFajrSub;

  /// No description provided for @nsTahajjud.
  ///
  /// In ar, this message translates to:
  /// **'منبه التهجد'**
  String get nsTahajjud;

  /// No description provided for @nsTahajjudSub.
  ///
  /// In ar, this message translates to:
  /// **'استيقاظ ليلي في الثلث الأخير أو وقت ثابت'**
  String get nsTahajjudSub;

  /// No description provided for @nsTahajjudLastThird.
  ///
  /// In ar, this message translates to:
  /// **'الثلث الأخير (تلقائي)'**
  String get nsTahajjudLastThird;

  /// No description provided for @nsTahajjudFixed.
  ///
  /// In ar, this message translates to:
  /// **'وقت ثابت'**
  String get nsTahajjudFixed;

  /// No description provided for @nsFajrExtra.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التنبيه للنوم الثقيل'**
  String get nsFajrExtra;

  /// No description provided for @nsFajrExtraSub.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحدي الفجر بعد الفجر (+دقائق)'**
  String get nsFajrExtraSub;

  /// No description provided for @nsPreviewTry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب التحدي الآن'**
  String get nsPreviewTry;

  /// No description provided for @nsBedtime.
  ///
  /// In ar, this message translates to:
  /// **'تذكير النوم'**
  String get nsBedtime;

  /// No description provided for @nsBedtimeSub.
  ///
  /// In ar, this message translates to:
  /// **'يساعدك على النوم مبكراً لتدرك الفجر'**
  String get nsBedtimeSub;

  /// No description provided for @nsBedtimeRelative.
  ///
  /// In ar, this message translates to:
  /// **'نسبي إلى الفجر'**
  String get nsBedtimeRelative;

  /// No description provided for @nsBedtimeRelativeSub.
  ///
  /// In ar, this message translates to:
  /// **'الفجر − {h, plural, one {{h} ساعة} two {{h} ساعتان} other {{h} ساعات}}'**
  String nsBedtimeRelativeSub(int h);

  /// No description provided for @nsSkipTonight.
  ///
  /// In ar, this message translates to:
  /// **'تخطي الليلة فقط'**
  String get nsSkipTonight;

  /// No description provided for @nsSkippedTonight.
  ///
  /// In ar, this message translates to:
  /// **'تم تخطي تذكير الليلة فقط'**
  String get nsSkippedTonight;

  /// No description provided for @nsPrePrayer.
  ///
  /// In ar, this message translates to:
  /// **'تذكير قبل الصلاة'**
  String get nsPrePrayer;

  /// No description provided for @nsPrePrayerSub.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه هادئ قبل كل صلاة مختارة'**
  String get nsPrePrayerSub;

  /// No description provided for @nsBeforePrayerBy.
  ///
  /// In ar, this message translates to:
  /// **'قبل الصلاة بـ:'**
  String get nsBeforePrayerBy;

  /// No description provided for @nsPostPrayer.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بعد الصلاة'**
  String get nsPostPrayer;

  /// No description provided for @nsPostPrayerSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بالأذكار بعد كل صلاة مختارة'**
  String get nsPostPrayerSub;

  /// No description provided for @nsAfterPrayerBy.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة بـ:'**
  String get nsAfterPrayerBy;

  /// No description provided for @nsAdhkarSection.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات أذكار الصباح والمساء'**
  String get nsAdhkarSection;

  /// No description provided for @nsMorning.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه أذكار الصباح'**
  String get nsMorning;

  /// No description provided for @nsMorningSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير مبارك بعد صلاة الفجر بساعة واحدة'**
  String get nsMorningSub;

  /// No description provided for @nsEvening.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه أذكار المساء'**
  String get nsEvening;

  /// No description provided for @nsEveningSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير مبارك بعد صلاة العصر بساعة واحدة'**
  String get nsEveningSub;

  /// No description provided for @nsPrayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get nsPrayerFajr;

  /// No description provided for @nsPrayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get nsPrayerDhuhr;

  /// No description provided for @nsPrayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get nsPrayerAsr;

  /// No description provided for @nsPrayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get nsPrayerMaghrib;

  /// No description provided for @nsPrayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get nsPrayerIsha;

  /// No description provided for @nsPrayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get nsPrayerSunrise;

  /// No description provided for @stAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والتفضيلات العامة'**
  String get stAppearance;

  /// No description provided for @stSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات والتفضيلات'**
  String get stSettingsTitle;

  /// No description provided for @ptFajrChallengeTip.
  ///
  /// In ar, this message translates to:
  /// **'تحدي استيقاظ الفجر'**
  String get ptFajrChallengeTip;

  /// No description provided for @ptLocationUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الموقع بنجاح'**
  String get ptLocationUpdated;

  /// No description provided for @ptLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل مواقيت الصلاة...'**
  String get ptLoading;

  /// No description provided for @ptLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب مواقيت الصلاة'**
  String get ptLoadFailed;

  /// No description provided for @ptLoadFailedSub.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من تفعيل خدمات الموقع والاتصال بالإنترنت'**
  String get ptLoadFailedSub;

  /// No description provided for @ptLoadingShort.
  ///
  /// In ar, this message translates to:
  /// **'يتم التحميل...'**
  String get ptLoadingShort;

  /// No description provided for @ptCorresponding.
  ///
  /// In ar, this message translates to:
  /// **' الموافق ل {date} م'**
  String ptCorresponding(String date);

  /// No description provided for @ptFajrChallenge.
  ///
  /// In ar, this message translates to:
  /// **'تحدي الفجر'**
  String get ptFajrChallenge;

  /// No description provided for @ptListFailed.
  ///
  /// In ar, this message translates to:
  /// **'عذرًا، فشل تحميل المواقيت'**
  String get ptListFailed;

  /// No description provided for @ptSourceTitle.
  ///
  /// In ar, this message translates to:
  /// **'مصدر المواقيت'**
  String get ptSourceTitle;

  /// No description provided for @ptSourceSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر المواقيت المحسوبة أو ابحث عن مسجد قريبك'**
  String get ptSourceSub;

  /// No description provided for @ptCalcSub.
  ///
  /// In ar, this message translates to:
  /// **'حسب حساب فقهي يعتمد على موقعك'**
  String get ptCalcSub;

  /// No description provided for @ptNearbyMosques.
  ///
  /// In ar, this message translates to:
  /// **'المساجد القريبة منك'**
  String get ptNearbyMosques;

  /// No description provided for @ptAllMosques.
  ///
  /// In ar, this message translates to:
  /// **'جميع المساجد — {country} ({count})'**
  String ptAllMosques(String country, int count);

  /// No description provided for @ptNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج حالياً'**
  String get ptNoResults;

  /// No description provided for @ptMosqueAdopted.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد ({name}) كمسجدك الرئيسي للمواقيت'**
  String ptMosqueAdopted(String name);

  /// No description provided for @ptMosqueFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل مواقيت هذا المسجد، حاول مجدداً'**
  String get ptMosqueFailed;

  /// No description provided for @ptMeters.
  ///
  /// In ar, this message translates to:
  /// **'{m} م'**
  String ptMeters(String m);

  /// No description provided for @ptKm.
  ///
  /// In ar, this message translates to:
  /// **'{km} كم'**
  String ptKm(String km);

  /// No description provided for @ptIqamaAfter.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة بعد'**
  String get ptIqamaAfter;

  /// No description provided for @ptPrayerAfter.
  ///
  /// In ar, this message translates to:
  /// **'{name} بعد'**
  String ptPrayerAfter(String name);

  /// No description provided for @ptAyatOff.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف نافذة الآية'**
  String get ptAyatOff;

  /// No description provided for @ptAyatOn.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل نافذة الآية'**
  String get ptAyatOn;

  /// No description provided for @ctCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ النص إلى الحافظة'**
  String get ctCopied;

  /// No description provided for @ctCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get ctCopy;

  /// No description provided for @ctCopyAll.
  ///
  /// In ar, this message translates to:
  /// **'نسخ النص كاملاً'**
  String get ctCopyAll;

  /// No description provided for @ctShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get ctShare;

  /// No description provided for @ctShareAll.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة النص كاملاً'**
  String get ctShareAll;

  /// No description provided for @ctClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get ctClose;

  /// No description provided for @ctCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get ctCancel;

  /// No description provided for @ctNoSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة للبحث'**
  String get ctNoSearchResults;

  /// No description provided for @ctSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get ctSearch;

  /// No description provided for @ctRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get ctRefresh;

  /// No description provided for @obPermNotif.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get obPermNotif;

  /// No description provided for @obPermNotifSub.
  ///
  /// In ar, this message translates to:
  /// **'لتنبيهك بأوقات الصلاة والأذكار'**
  String get obPermNotifSub;

  /// No description provided for @obPermLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الجغرافي'**
  String get obPermLocation;

  /// No description provided for @obPermLocationSub.
  ///
  /// In ar, this message translates to:
  /// **'لتحديد مواقيت الصلاة بدقة حسب موقعك'**
  String get obPermLocationSub;

  /// No description provided for @obPermOverlay.
  ///
  /// In ar, this message translates to:
  /// **'العرض فوق التطبيقات'**
  String get obPermOverlay;

  /// No description provided for @obPermOverlaySub.
  ///
  /// In ar, this message translates to:
  /// **'لعرض الأذكار والآيات تلقائياً على الشاشة'**
  String get obPermOverlaySub;

  /// No description provided for @obWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في حصن المسلم'**
  String get obWelcome;

  /// No description provided for @obSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إلى بعض الأذونات لتعمل جميع المميزات بشكل صحيح'**
  String get obSubtitle;

  /// No description provided for @obSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get obSkip;

  /// No description provided for @azEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get azEmpty;

  /// No description provided for @duCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الدعاء إلى الحافظة'**
  String get duCopied;

  /// No description provided for @duLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات الأدعية'**
  String get duLoadFailed;

  /// No description provided for @duQuranSection.
  ///
  /// In ar, this message translates to:
  /// **'أدعية القرآن الكريم'**
  String get duQuranSection;

  /// No description provided for @duSunnahSection.
  ///
  /// In ar, this message translates to:
  /// **'أدعية السنة النبوية'**
  String get duSunnahSection;

  /// No description provided for @duAdabSection.
  ///
  /// In ar, this message translates to:
  /// **'فضل وآداب الدعاء'**
  String get duAdabSection;

  /// No description provided for @duQuranBadge.
  ///
  /// In ar, this message translates to:
  /// **'قرآن كريم'**
  String get duQuranBadge;

  /// No description provided for @duSunnahBadge.
  ///
  /// In ar, this message translates to:
  /// **'سنة نبوية'**
  String get duSunnahBadge;

  /// No description provided for @duShareSubject.
  ///
  /// In ar, this message translates to:
  /// **'دعاء رقم {n}'**
  String duShareSubject(int n);

  /// No description provided for @rqLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات الرقية الشرعية'**
  String get rqLoadFailed;

  /// No description provided for @rqItems.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, other {# فقرة / رقية}}'**
  String rqItems(int n);

  /// No description provided for @asCopiedDefault.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ ✿'**
  String get asCopiedDefault;

  /// No description provided for @asTapHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للعرض، اضغط مطولة للنسخ'**
  String get asTapHint;

  /// No description provided for @azSpeedTitle.
  ///
  /// In ar, this message translates to:
  /// **'سرعة العداد التلقائي'**
  String get azSpeedTitle;

  /// No description provided for @azSeconds.
  ///
  /// In ar, this message translates to:
  /// **'الوقت بالثانية'**
  String get azSeconds;

  /// No description provided for @azAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get azAuto;

  /// No description provided for @azReset.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get azReset;

  /// No description provided for @azTimes.
  ///
  /// In ar, this message translates to:
  /// **'{m, plural, one {مرة واحدة} two {{m} مرتان} other {{m} مرات}}'**
  String azTimes(int m);

  /// No description provided for @azTimesHundred.
  ///
  /// In ar, this message translates to:
  /// **'{m} مرة'**
  String azTimesHundred(int m);

  /// No description provided for @azOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'الذكر {i} من {n}'**
  String azOfTotal(int i, int n);

  /// No description provided for @azCopiedDhikr.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الذكر إلى الحافظة'**
  String get azCopiedDhikr;

  /// No description provided for @azSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get azSave;

  /// No description provided for @azCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ إلى الحافظة'**
  String get azCopied;

  /// No description provided for @azSharePrefix.
  ///
  /// In ar, this message translates to:
  /// **'من أذكار {cat}'**
  String azSharePrefix(Object cat);

  /// No description provided for @msSaveFolder.
  ///
  /// In ar, this message translates to:
  /// **'اختر مجلد الحفظ'**
  String get msSaveFolder;

  /// No description provided for @msBackupSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ النسخة الاحتياطية: {f}'**
  String msBackupSaved(String f);

  /// No description provided for @msExportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير: {e}'**
  String msExportFailed(String e);

  /// No description provided for @msImported.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد البيانات بنجاح'**
  String get msImported;

  /// No description provided for @msImportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد: {e}'**
  String msImportFailed(String e);

  /// No description provided for @msAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الذكر بنجاح!'**
  String get msAdded;

  /// No description provided for @msEdited.
  ///
  /// In ar, this message translates to:
  /// **'تم تعديل الذكر بنجاح!'**
  String get msEdited;

  /// No description provided for @msDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الذكر بنجاح!'**
  String get msDeleted;

  /// No description provided for @msPickCount.
  ///
  /// In ar, this message translates to:
  /// **'اختر عدد التسبيحات'**
  String get msPickCount;

  /// No description provided for @msCountHint.
  ///
  /// In ar, this message translates to:
  /// **'عدد التسبيحات (افتراضي مفتوح)'**
  String get msCountHint;

  /// No description provided for @msStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get msStart;

  /// No description provided for @msEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get msEdit;

  /// No description provided for @msDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get msDelete;

  /// No description provided for @msAddNew.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ذكر جديد'**
  String get msAddNew;

  /// No description provided for @msRestoreTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الأذكار الافتراضية؟'**
  String get msRestoreTitle;

  /// No description provided for @msRestoreBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف جميع أذكارك الحالية واستبدالها بالقائمة الافتراضية مع السرعات الجديدة.'**
  String get msRestoreBody;

  /// No description provided for @msRestore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get msRestore;

  /// No description provided for @msHideScores.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء النقاط'**
  String get msHideScores;

  /// No description provided for @msShowScores.
  ///
  /// In ar, this message translates to:
  /// **'إظهار النقاط'**
  String get msShowScores;

  /// No description provided for @msResetDefault.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الافتراضي'**
  String get msResetDefault;

  /// No description provided for @msExport.
  ///
  /// In ar, this message translates to:
  /// **'تصدير البيانات'**
  String get msExport;

  /// No description provided for @msImport.
  ///
  /// In ar, this message translates to:
  /// **'استيراد البيانات'**
  String get msImport;

  /// No description provided for @msAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ذكر'**
  String get msAddTitle;

  /// No description provided for @msEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل ذكر'**
  String get msEditTitle;

  /// No description provided for @msFieldDhikr.
  ///
  /// In ar, this message translates to:
  /// **'الذكر *'**
  String get msFieldDhikr;

  /// No description provided for @msFieldBenefit.
  ///
  /// In ar, this message translates to:
  /// **'الفضل'**
  String get msFieldBenefit;

  /// No description provided for @msFieldSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get msFieldSource;

  /// No description provided for @msFieldSpeed.
  ///
  /// In ar, this message translates to:
  /// **'سرعة العداد التلقائي (بالثانية)'**
  String get msFieldSpeed;

  /// No description provided for @msCounterTitle.
  ///
  /// In ar, this message translates to:
  /// **'عداد الذكر'**
  String get msCounterTitle;

  /// No description provided for @msVirtue.
  ///
  /// In ar, this message translates to:
  /// **'الفضل: {t}'**
  String msVirtue(String t);

  /// No description provided for @msSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: {t}'**
  String msSource(String t);

  /// No description provided for @msOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get msOpen;

  /// No description provided for @msSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get msSave;

  /// No description provided for @stDarkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get stDarkMode;

  /// No description provided for @stDarkOn.
  ///
  /// In ar, this message translates to:
  /// **'المظهر الليلي مفعّل لراحة العين'**
  String get stDarkOn;

  /// No description provided for @stDarkOff.
  ///
  /// In ar, this message translates to:
  /// **'المظهر النهاري الفاتح مفعّل'**
  String get stDarkOff;

  /// No description provided for @stDefaultHome.
  ///
  /// In ar, this message translates to:
  /// **'الواجهة الافتراضية'**
  String get stDefaultHome;

  /// No description provided for @stDefaultHomeSub.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التي تظهر عند تشغيل التطبيق'**
  String get stDefaultHomeSub;

  /// No description provided for @stHomeAzkarSub.
  ///
  /// In ar, this message translates to:
  /// **'أذكار اليوم والليلة وحصن المسلم'**
  String get stHomeAzkarSub;

  /// No description provided for @stHomeMisbahaSub.
  ///
  /// In ar, this message translates to:
  /// **'عداد التسبيح والأذكار المخصصة'**
  String get stHomeMisbahaSub;

  /// No description provided for @stHomePrayerSub.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الأذان والتنبيهات والقبلة'**
  String get stHomePrayerSub;

  /// No description provided for @stHomeSet.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين الصفحة الرئيسية (تُطبق عند إعادة الفتح)'**
  String get stHomeSet;

  /// No description provided for @stLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة / Language'**
  String get stLanguageTitle;

  /// No description provided for @stLanguagePicker.
  ///
  /// In ar, this message translates to:
  /// **'اللغة / Language / Langue'**
  String get stLanguagePicker;

  /// No description provided for @stLanguagePickerSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغة واجهة التطبيق'**
  String get stLanguagePickerSub;

  /// No description provided for @stLangArSub.
  ///
  /// In ar, this message translates to:
  /// **'لغة الواجهة الافتراضية'**
  String get stLangArSub;

  /// No description provided for @stLangEnSub.
  ///
  /// In ar, this message translates to:
  /// **'Application language'**
  String get stLangEnSub;

  /// No description provided for @stLangFrSub.
  ///
  /// In ar, this message translates to:
  /// **'Langue de l\'interface'**
  String get stLangFrSub;

  /// No description provided for @stInteraction.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة والتفاعل'**
  String get stInteraction;

  /// No description provided for @stClickSound.
  ///
  /// In ar, this message translates to:
  /// **'صوت النقرة'**
  String get stClickSound;

  /// No description provided for @stClickSoundSub.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل صوت خفيف عند الضغط على المسبحة'**
  String get stClickSoundSub;

  /// No description provided for @stHaptic.
  ///
  /// In ar, this message translates to:
  /// **'الاهتزاز اللمسي'**
  String get stHaptic;

  /// No description provided for @stHapticSub.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز الهاتف عند كل تسبيحة للتأكيد'**
  String get stHapticSub;

  /// No description provided for @stReminder.
  ///
  /// In ar, this message translates to:
  /// **'التذكير التلقائي بالأذكار'**
  String get stReminder;

  /// No description provided for @stFloatingDhikr.
  ///
  /// In ar, this message translates to:
  /// **'أذكار عائمة دورية'**
  String get stFloatingDhikr;

  /// No description provided for @stFloatingDhikrSub.
  ///
  /// In ar, this message translates to:
  /// **'ظهور نافذة ذكر قصيرة تلقائياً فوق التطبيقات'**
  String get stFloatingDhikrSub;

  /// No description provided for @stReminderRate.
  ///
  /// In ar, this message translates to:
  /// **'وتيرة التذكير'**
  String get stReminderRate;

  /// No description provided for @stReminderRateSub.
  ///
  /// In ar, this message translates to:
  /// **'الفترة الفاصلة بين كل ذكر وآخر'**
  String get stReminderRateSub;

  /// No description provided for @stEveryHour.
  ///
  /// In ar, this message translates to:
  /// **'كل ساعة'**
  String get stEveryHour;

  /// No description provided for @stEveryMinutes.
  ///
  /// In ar, this message translates to:
  /// **'كل {m, plural, one {{m} دقيقة} two {{m} دقيقتان} other {{m} دقائق}}'**
  String stEveryMinutes(int m);

  /// No description provided for @stIntervalTitle.
  ///
  /// In ar, this message translates to:
  /// **'وتيرة التذكير التلقائي'**
  String get stIntervalTitle;

  /// No description provided for @stIntervalSub.
  ///
  /// In ar, this message translates to:
  /// **'المدة الزمنية بين كل ذكر عائم وآخر'**
  String get stIntervalSub;

  /// No description provided for @stOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'إذن الظهور فوق التطبيقات'**
  String get stOverlayTitle;

  /// No description provided for @stOverlayBody.
  ///
  /// In ar, this message translates to:
  /// **'ليتمكن التطبيق من عرض الأذكار القصيرة أثناء تصفحك للتطبيقات الأخرى، يحتاج إلى منح إذن الظهور فوق التطبيقات. هل تود تفعيله الآن؟'**
  String get stOverlayBody;

  /// No description provided for @stActivateNow.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الآن'**
  String get stActivateNow;

  /// No description provided for @stHomePicker.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الرئيسية الافتراضية'**
  String get stHomePicker;

  /// No description provided for @stHomePickerSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر الواجهة التي تبدأ مع فتح التطبيق'**
  String get stHomePickerSub;

  /// No description provided for @stPrayerData.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة ومصدر البيانات'**
  String get stPrayerData;

  /// No description provided for @stSourcePicker.
  ///
  /// In ar, this message translates to:
  /// **'مصدر مواقيت الصلاة'**
  String get stSourcePicker;

  /// No description provided for @stSourcePickerSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر بين مواقيت المسجد المعتمدة أو الحساب الفلكي الدقيق'**
  String get stSourcePickerSub;

  /// No description provided for @stSourceMosque.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت المسجد (أونلاين مع كاش)'**
  String get stSourceMosque;

  /// No description provided for @stSourceMosqueSub.
  ///
  /// In ar, this message translates to:
  /// **'جلب المواقيت المعتمدة لمسجدك المحدد عبر Mawaqit وحفظها للعمل بدون إنترنت'**
  String get stSourceMosqueSub;

  /// No description provided for @stSourceCalc.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت محسوبة (أوفلاين بالكامل)'**
  String get stSourceCalc;

  /// No description provided for @stSourceCalcMode.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت محسوبة فلكياً (أوفلاين)'**
  String get stSourceCalcMode;

  /// No description provided for @stSourceCalcSub.
  ///
  /// In ar, this message translates to:
  /// **'حساب مواقيت الصلاة فلكياً بناءً على إحداثيات الموقع والمذهب الفقهي دون الحاجة للإنترنت'**
  String get stSourceCalcSub;

  /// No description provided for @stSourceMosqueSet.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين المصدر: مواقيت المسجد'**
  String get stSourceMosqueSet;

  /// No description provided for @stSourceCalcSet.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين المصدر: مواقيت محسوبة'**
  String get stSourceCalcSet;

  /// No description provided for @stCalcPicker.
  ///
  /// In ar, this message translates to:
  /// **'طريقة حساب مواقيت الصلاة'**
  String get stCalcPicker;

  /// No description provided for @stCalcPickerSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر الهيئة أو المجمع الفلكي المعتمد في منطقتك'**
  String get stCalcPickerSub;

  /// No description provided for @stCalcSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ طريقة الحساب وإعادة ضبط المواقيت'**
  String get stCalcSaved;

  /// No description provided for @stAsrPicker.
  ///
  /// In ar, this message translates to:
  /// **'مذهب صلاة العصر'**
  String get stAsrPicker;

  /// No description provided for @stAsrPickerSub.
  ///
  /// In ar, this message translates to:
  /// **'تحديد وقت دخول صلاة العصر حسب المذاهب الفقهية'**
  String get stAsrPickerSub;

  /// No description provided for @stAsrShafi.
  ///
  /// In ar, this message translates to:
  /// **'الجمهور (شافعي، مالكي، حنبلي)'**
  String get stAsrShafi;

  /// No description provided for @stAsrShafiSub.
  ///
  /// In ar, this message translates to:
  /// **'عندما يصير ظل كل شيء مثله'**
  String get stAsrShafiSub;

  /// No description provided for @stAsrHanafi.
  ///
  /// In ar, this message translates to:
  /// **'المذهب الحنفي'**
  String get stAsrHanafi;

  /// No description provided for @stAsrHanafiSub.
  ///
  /// In ar, this message translates to:
  /// **'عندما يصير ظل كل شيء مثليه'**
  String get stAsrHanafiSub;

  /// No description provided for @stAsrSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ مذهب العصر'**
  String get stAsrSaved;

  /// No description provided for @stMethodMakkah.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى (مكة المكرمة)'**
  String get stMethodMakkah;

  /// No description provided for @stMethodMakkahSub.
  ///
  /// In ar, this message translates to:
  /// **'المملكة العربية السعودية والخليج العربي'**
  String get stMethodMakkahSub;

  /// No description provided for @stMethodEgypt.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة العامة المصرية للمساحة'**
  String get stMethodEgypt;

  /// No description provided for @stMethodEgyptSub.
  ///
  /// In ar, this message translates to:
  /// **'مصر، السودان، وبعض دول إفريقيا'**
  String get stMethodEgyptSub;

  /// No description provided for @stMethodMwl.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get stMethodMwl;

  /// No description provided for @stMethodMwlSub.
  ///
  /// In ar, this message translates to:
  /// **'أوروبا والشرق الأقصى وأمريكا'**
  String get stMethodMwlSub;

  /// No description provided for @stMethodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية بكراتشي'**
  String get stMethodKarachi;

  /// No description provided for @stMethodKarachiSub.
  ///
  /// In ar, this message translates to:
  /// **'باكستان، الهند، بنغلاديش، وأفغانستان'**
  String get stMethodKarachiSub;

  /// No description provided for @stMethodIsna.
  ///
  /// In ar, this message translates to:
  /// **'الجمعية الإسلامية لأمريكا الشمالية (ISNA)'**
  String get stMethodIsna;

  /// No description provided for @stMethodIsnaSub.
  ///
  /// In ar, this message translates to:
  /// **'الولايات المتحدة وكندا'**
  String get stMethodIsnaSub;

  /// No description provided for @stMethodKuwait.
  ///
  /// In ar, this message translates to:
  /// **'دولة الكويت'**
  String get stMethodKuwait;

  /// No description provided for @stMethodKuwaitSub.
  ///
  /// In ar, this message translates to:
  /// **'الكويت (فجر 18، عشاء 17.5)'**
  String get stMethodKuwaitSub;

  /// No description provided for @stMethodQatar.
  ///
  /// In ar, this message translates to:
  /// **'دولة قطر'**
  String get stMethodQatar;

  /// No description provided for @stMethodQatarSub.
  ///
  /// In ar, this message translates to:
  /// **'قطر (فجر 18، العشاء بعد المغرب بـ 90 دقيقة)'**
  String get stMethodQatarSub;

  /// No description provided for @stMethodSingapore.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة'**
  String get stMethodSingapore;

  /// No description provided for @stMethodSingaporeSub.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة وماليزيا (فجر 20، عشاء 18)'**
  String get stMethodSingaporeSub;

  /// No description provided for @stMethodTurkey.
  ///
  /// In ar, this message translates to:
  /// **'رئاسة الشؤون الدينية التركية'**
  String get stMethodTurkey;

  /// No description provided for @stMethodTurkeySub.
  ///
  /// In ar, this message translates to:
  /// **'تركيا (ديانة)'**
  String get stMethodTurkeySub;

  /// No description provided for @stMethodDubai.
  ///
  /// In ar, this message translates to:
  /// **'الإمارات والخليج (دبي)'**
  String get stMethodDubai;

  /// No description provided for @stMethodDubaiSub.
  ///
  /// In ar, this message translates to:
  /// **'الإمارات ومنطقة الخليج (18.2)'**
  String get stMethodDubaiSub;

  /// No description provided for @stMethodMoon.
  ///
  /// In ar, this message translates to:
  /// **'لجنة رؤية الهلال'**
  String get stMethodMoon;

  /// No description provided for @stMethodMoonSub.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية والمناطق القطبية'**
  String get stMethodMoonSub;

  /// No description provided for @stCalcMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get stCalcMethod;

  /// No description provided for @stCalcMethodSub.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة الفلكية المعتمدة لزوايا الفجر والعشاء'**
  String get stCalcMethodSub;

  /// No description provided for @stAsrMethod.
  ///
  /// In ar, this message translates to:
  /// **'مذهب صلاة العصر'**
  String get stAsrMethod;

  /// No description provided for @stAsrMethodSub.
  ///
  /// In ar, this message translates to:
  /// **'معيار تحديد ظل الزوال لدخول وقت العصر'**
  String get stAsrMethodSub;

  /// No description provided for @stDst.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت الصيفي'**
  String get stDst;

  /// No description provided for @stDstSub.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ساعة واحدة لمواقيت الصلاة تلقائياً'**
  String get stDstSub;

  /// No description provided for @stManualTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل مواقيت الصلاة يدوياً'**
  String get stManualTitle;

  /// No description provided for @stManualTileSub.
  ///
  /// In ar, this message translates to:
  /// **'زيادة أو إنقاص دقائق لتطابق أذان منطقتك'**
  String get stManualTileSub;

  /// No description provided for @stReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط'**
  String get stReset;

  /// No description provided for @stManualSub.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك زيادة أو إنقاص دقائق محددة لكل صلاة لتطابق أذان مسجدك'**
  String get stManualSub;

  /// No description provided for @stZeroMin.
  ///
  /// In ar, this message translates to:
  /// **'0 دقيقة'**
  String get stZeroMin;

  /// No description provided for @stMinDelta.
  ///
  /// In ar, this message translates to:
  /// **'{signed} د'**
  String stMinDelta(String signed);

  /// No description provided for @stManualSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تعديلات المواقيت بنجاح'**
  String get stManualSaved;

  /// No description provided for @stSaveEdits.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get stSaveEdits;

  /// No description provided for @stSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get stSave;

  /// No description provided for @stIqamaTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذه الإقامة (دقائق بعد الأذان)'**
  String get stIqamaTitle;

  /// No description provided for @stIqamaSub.
  ///
  /// In ar, this message translates to:
  /// **'حدد عدد دقائق الإقامة بعد الأذان لكل صلاة لعرض عد تنازلي دقيق'**
  String get stIqamaSub;

  /// No description provided for @stIqamaTile.
  ///
  /// In ar, this message translates to:
  /// **'هذه الإقامة'**
  String get stIqamaTile;

  /// No description provided for @stIqamaTileSub.
  ///
  /// In ar, this message translates to:
  /// **'تحديد دقائق الإقامة بعد الأذان لكل صلاة'**
  String get stIqamaTileSub;

  /// No description provided for @stNoAdjust.
  ///
  /// In ar, this message translates to:
  /// **'بدون تعديل'**
  String get stNoAdjust;

  /// No description provided for @stNoIqama.
  ///
  /// In ar, this message translates to:
  /// **'بدون إقامة'**
  String get stNoIqama;

  /// No description provided for @stIqamaMinutes.
  ///
  /// In ar, this message translates to:
  /// **'+{m} دقيقة'**
  String stIqamaMinutes(int m);

  /// No description provided for @stIqamaSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات الإقامة بنجاح'**
  String get stIqamaSaved;

  /// No description provided for @stHijriTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التاريخ الهجري'**
  String get stHijriTitle;

  /// No description provided for @stHijriSub.
  ///
  /// In ar, this message translates to:
  /// **'قم بتقديم أو تأخير التاريخ الهجري يوماً أو أكثر لمطابقة الرؤية الشرعية'**
  String get stHijriSub;

  /// No description provided for @stHijriExact.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ مطابق للحساب الفلكي'**
  String get stHijriExact;

  /// No description provided for @stHijriAdjusted.
  ///
  /// In ar, this message translates to:
  /// **'معدّل بـ ({text})'**
  String stHijriAdjusted(String text);

  /// No description provided for @stHijriDays.
  ///
  /// In ar, this message translates to:
  /// **'{d} يوم'**
  String stHijriDays(int d);

  /// No description provided for @stAdjust.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get stAdjust;

  /// No description provided for @stHijriSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تعديل التاريخ الهجري'**
  String get stHijriSaved;

  /// No description provided for @stGpsRefreshed.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الموقع ومواقيت الصلاة بنجاح'**
  String get stGpsRefreshed;

  /// No description provided for @stGpsFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث الموقع، يرجى التحقق من تفعيل الـ GPS'**
  String get stGpsFailed;

  /// No description provided for @stGpsTile.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الجغرافي (GPS)'**
  String get stGpsTile;

  /// No description provided for @stRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get stRefresh;

  /// No description provided for @stCoords.
  ///
  /// In ar, this message translates to:
  /// **'الإحداثيات: {lat}, {lon}'**
  String stCoords(String lat, String lon);

  /// No description provided for @stNoMosque.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد مسجد بعد'**
  String get stNoMosque;

  /// No description provided for @stOpenMapChoose.
  ///
  /// In ar, this message translates to:
  /// **'انقر لفتح الخريطة واختيار مسجدك'**
  String get stOpenMapChoose;

  /// No description provided for @stCityChange.
  ///
  /// In ar, this message translates to:
  /// **'المدينة: {city} • انقر للتغيير'**
  String stCityChange(String city);

  /// No description provided for @stChangeMosque.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المسجد'**
  String get stChangeMosque;

  /// No description provided for @stChooseMosque.
  ///
  /// In ar, this message translates to:
  /// **'اختيار مسجد'**
  String get stChooseMosque;

  /// No description provided for @stMosqueBadge.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت المسجد'**
  String get stMosqueBadge;

  /// No description provided for @stCalcBadge.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة'**
  String get stCalcBadge;

  /// No description provided for @stNotifHub.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات والأذان'**
  String get stNotifHub;

  /// No description provided for @stHubTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص التنبيهات والأذان'**
  String get stHubTitle;

  /// No description provided for @stHubSub.
  ///
  /// In ar, this message translates to:
  /// **'الإشعار الدائم، تحدي الفجر، وتنبيهات أذكار الصباح والمساء'**
  String get stHubSub;

  /// No description provided for @stAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get stAdvanced;

  /// No description provided for @stSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الإعدادات'**
  String get stSearchHint;

  /// No description provided for @stAdvancedMode.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات المتقدمة'**
  String get stAdvancedMode;

  /// No description provided for @stAdvancedModeSub.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الخيارات التقنية (الفروق، الإقامة، الضبط الدقيق)'**
  String get stAdvancedModeSub;

  /// No description provided for @stHiddenAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'بعض الإعدادات التقنية مخفية'**
  String get stHiddenAdvanced;

  /// No description provided for @stDiagTile.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص المتقدم'**
  String get stDiagTile;

  /// No description provided for @stDiagTileSub.
  ///
  /// In ar, this message translates to:
  /// **'حالة الأذونات والمنبهات المجدولة والاختبار'**
  String get stDiagTileSub;

  /// No description provided for @stAbout.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق والمشاركة'**
  String get stAbout;

  /// No description provided for @stAboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن حصن المسلم والإصدار'**
  String get stAboutApp;

  /// No description provided for @stAboutAppSub.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {v} • مفتوح المصدر'**
  String stAboutAppSub(String v);

  /// No description provided for @stOfficialSite.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الرسمي للشيخ سعيد بن وهف'**
  String get stOfficialSite;

  /// No description provided for @stOfficialSiteSub.
  ///
  /// In ar, this message translates to:
  /// **'مؤلف كتاب حصن المسلم رحمه الله'**
  String get stOfficialSiteSub;

  /// No description provided for @stGithub.
  ///
  /// In ar, this message translates to:
  /// **'المشروع على GitHub'**
  String get stGithub;

  /// No description provided for @stGithubSub.
  ///
  /// In ar, this message translates to:
  /// **'مساهمة في التطوير وكود المصدر'**
  String get stGithubSub;

  /// No description provided for @stGithubSheetSub.
  ///
  /// In ar, this message translates to:
  /// **'المستودع البرمجي للتطبيق على GitHub'**
  String get stGithubSheetSub;

  /// No description provided for @stAboutSheetLine.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {v} • تطبيق إسلامي مفتوح المصدر'**
  String stAboutSheetLine(String v);

  /// No description provided for @mmSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم المسجد أو المدينة...'**
  String get mmSearchHint;

  /// No description provided for @mmTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المساجد'**
  String get mmTitle;

  /// No description provided for @mmCloseSearch.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق البحث'**
  String get mmCloseSearch;

  /// No description provided for @mmSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get mmSearch;

  /// No description provided for @mmShowMap.
  ///
  /// In ar, this message translates to:
  /// **'عرض على الخريطة'**
  String get mmShowMap;

  /// No description provided for @mmShowList.
  ///
  /// In ar, this message translates to:
  /// **'عرض القائمة'**
  String get mmShowList;

  /// No description provided for @mmChangeCountry.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدولة'**
  String get mmChangeCountry;

  /// No description provided for @mmMosqueCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one {{count} مسجد} two {{count} مسجداً} other {{count} مسجد}}'**
  String mmMosqueCount(int count);

  /// No description provided for @mmOfflineBanner.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل بالإنترنت — يتم عرض المساجد المخزنة مسبقاً'**
  String get mmOfflineBanner;

  /// No description provided for @mmLocateMe.
  ///
  /// In ar, this message translates to:
  /// **'موقعي الحالي'**
  String get mmLocateMe;

  /// No description provided for @mmCountryPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر الدولة لعرض المساجد'**
  String get mmCountryPickerTitle;

  /// No description provided for @mmAdoptMosque.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد كمسجد رئيسي'**
  String get mmAdoptMosque;

  /// No description provided for @mmRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get mmRetry;

  /// No description provided for @mmEmptyNoMosques.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مساجد بانتظار التحميل'**
  String get mmEmptyNoMosques;

  /// No description provided for @mmEmptyNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج مطابقة'**
  String get mmEmptyNoResults;

  /// No description provided for @mmRefreshTimes.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المواقيت'**
  String get mmRefreshTimes;

  /// No description provided for @mmActiveMosqueBadge.
  ///
  /// In ar, this message translates to:
  /// **'هذا هو المسجد المعتمد حالياً في التطبيق'**
  String get mmActiveMosqueBadge;

  /// No description provided for @mmDistanceKm.
  ///
  /// In ar, this message translates to:
  /// **'يبعد {d} كم'**
  String mmDistanceKm(Object d);

  /// No description provided for @mmAdoptedNow.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين ({name}) كمسجدك الرئيسي للمواقيت'**
  String mmAdoptedNow(Object name);

  /// No description provided for @mmActiveMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد المعتمد'**
  String get mmActiveMosque;

  /// No description provided for @mmAdoptThis.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد هذا المسجد للمواقيت'**
  String get mmAdoptThis;

  /// No description provided for @mmDirections.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاهات في الخريطة'**
  String get mmDirections;

  /// No description provided for @mmDirectionsFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الاتجاهات. لا يوجد تطبيق خرائط.'**
  String get mmDirectionsFailed;

  /// No description provided for @mmShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة المواقيت'**
  String get mmShare;

  /// No description provided for @mmJumua.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة: {t}'**
  String mmJumua(Object t);

  /// No description provided for @mmFriday.
  ///
  /// In ar, this message translates to:
  /// **'صلاة الجمعة'**
  String get mmFriday;

  /// No description provided for @mmAppName.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق حصن المسلم'**
  String get mmAppName;

  /// No description provided for @mmPrayerTimesFor.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة لـ {name} ({city}):'**
  String mmPrayerTimesFor(Object city, Object name);

  /// No description provided for @mmErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'**
  String get mmErrorNetwork;

  /// No description provided for @mmErrorParsing.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في قراءة بيانات الخادم. تم تحديث بيانات المساجد، يرجى المحاولة لاحقاً.'**
  String get mmErrorParsing;

  /// No description provided for @mmErrorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على بيانات المساجد لهذه الدولة.'**
  String get mmErrorNotFound;

  /// No description provided for @mmErrorServer.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في خادم مواقيت. يرجى المحاولة لاحقاً.'**
  String get mmErrorServer;

  /// No description provided for @mmErrorTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال بالخادم. تحقق من اتصالك وحاول مرة أخرى.'**
  String get mmErrorTimeout;

  /// No description provided for @mmErrorGeneral.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل قائمة المساجد. تأكد من الاتصال بالإنترنت.'**
  String get mmErrorGeneral;

  /// No description provided for @mmScheduleErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم لتحميل مواقيت المسجد.'**
  String get mmScheduleErrorNetwork;

  /// No description provided for @mmScheduleErrorParsing.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في قراءة مواقيت المسجد. قد يكون تنسيق البيانات قد تغير.'**
  String get mmScheduleErrorParsing;

  /// No description provided for @mmScheduleErrorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مواقيت لهذا المسجد.'**
  String get mmScheduleErrorNotFound;

  /// No description provided for @mmScheduleErrorServer.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في خادم مواقيت. يرجى المحاولة لاحقاً.'**
  String get mmScheduleErrorServer;

  /// No description provided for @mmScheduleErrorTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال عند تحميل المواقيت.'**
  String get mmScheduleErrorTimeout;

  /// No description provided for @mmScheduleErrorGeneral.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل مواقيت هذا المسجد.'**
  String get mmScheduleErrorGeneral;

  /// No description provided for @nsExtraAdhkarSection.
  ///
  /// In ar, this message translates to:
  /// **'أذكار إضافية'**
  String get nsExtraAdhkarSection;

  /// No description provided for @nsWakeupAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه أذكار الاستيقاظ'**
  String get nsWakeupAdhkar;

  /// No description provided for @nsWakeupAdhkarSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير مبارك بأذكار الاستيقاظ من النوم عند الفجر'**
  String get nsWakeupAdhkarSub;

  /// No description provided for @nsSleepAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه أذكار النوم'**
  String get nsSleepAdhkar;

  /// No description provided for @nsSleepAdhkarSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير مبارك بأذكار النوم قبل موعد نومك'**
  String get nsSleepAdhkarSub;

  /// No description provided for @nsFridayKahf.
  ///
  /// In ar, this message translates to:
  /// **'تذكير سورة الكهف يوم الجمعة'**
  String get nsFridayKahf;

  /// No description provided for @nsFridayKahfSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير صباح كل جمعة بقراءة سورة الكهف نوراً بين الجمعتين'**
  String get nsFridayKahfSub;

  /// No description provided for @nsFridayKahfTitle.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف'**
  String get nsFridayKahfTitle;

  /// No description provided for @nsFridayKahfBody.
  ///
  /// In ar, this message translates to:
  /// **'لا تنس قراءة سورة الكهف اليوم — نور ما بين الجمعتين'**
  String get nsFridayKahfBody;

  /// No description provided for @nsDndSection.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الصامت التلقائي (DND)'**
  String get nsDndSection;

  /// No description provided for @nsDndTitle.
  ///
  /// In ar, this message translates to:
  /// **'كتم الهاتف أثناء الصلاة'**
  String get nsDndTitle;

  /// No description provided for @nsDndSub.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل عدم الإزعاج تلقائياً عند دخول وقت الصلاة لمنع الرنين في المسجد'**
  String get nsDndSub;

  /// No description provided for @nsDndDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدة الكتم بعد الأذان'**
  String get nsDndDuration;

  /// No description provided for @nsDndPermNeeded.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب إذن الوصول إلى سياسة عدم الإزعاج'**
  String get nsDndPermNeeded;

  /// No description provided for @nsDndPermGrant.
  ///
  /// In ar, this message translates to:
  /// **'منح إذن عدم الإزعاج'**
  String get nsDndPermGrant;

  /// No description provided for @nsDndMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{m, plural, one {{m} دقيقة} two {{m} دقيقتان} other {{m} دقائق}}'**
  String nsDndMinutes(int m);

  /// No description provided for @diagDndTitle.
  ///
  /// In ar, this message translates to:
  /// **'سياسة عدم الإزعاج (DND)'**
  String get diagDndTitle;

  /// No description provided for @diagDndOk.
  ///
  /// In ar, this message translates to:
  /// **'ممنوح — الكتم التلقائي أثناء الصلاة متاح'**
  String get diagDndOk;

  /// No description provided for @diagDndDenied.
  ///
  /// In ar, this message translates to:
  /// **'غير ممنوح — التطبيق لا يستطيع كتم الهاتف تلقائياً'**
  String get diagDndDenied;

  /// No description provided for @ptTrackerTitle.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الصلوات'**
  String get ptTrackerTitle;

  /// No description provided for @ptLevelTitle.
  ///
  /// In ar, this message translates to:
  /// **'المستوى {level}'**
  String ptLevelTitle(int level);

  /// No description provided for @ptDailyGoal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف اليومي'**
  String get ptDailyGoal;

  /// No description provided for @ptEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get ptEdit;

  /// No description provided for @ptGoalToday.
  ///
  /// In ar, this message translates to:
  /// **'هدف اليوم'**
  String get ptGoalToday;

  /// No description provided for @ptOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على الصلاة'**
  String get ptOverview;

  /// No description provided for @ptLast30Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٣٠ يوماً'**
  String get ptLast30Days;

  /// No description provided for @ptEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات صلاة مسجلة بعد'**
  String get ptEmptyTitle;

  /// No description provided for @ptEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بتسجيل صلواتك لرؤية النظرة العامة هنا'**
  String get ptEmptyHint;

  /// No description provided for @ptGoalDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'هدفك اليومي'**
  String get ptGoalDialogTitle;

  /// No description provided for @ptGoalDialogHint.
  ///
  /// In ar, this message translates to:
  /// **'عدد الصلوات المطلوبة يومياً'**
  String get ptGoalDialogHint;

  /// No description provided for @ptSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get ptSave;

  /// No description provided for @ptTotalPrayers.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الصلوات'**
  String get ptTotalPrayers;

  /// No description provided for @ptOnTimeRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الالتزام'**
  String get ptOnTimeRate;

  /// No description provided for @ptTotalPoints.
  ///
  /// In ar, this message translates to:
  /// **'مجموع النقاط'**
  String get ptTotalPoints;

  /// No description provided for @ptHowPrayed.
  ///
  /// In ar, this message translates to:
  /// **'كيف صليت؟'**
  String get ptHowPrayed;

  /// No description provided for @ptOptTakbeer.
  ///
  /// In ar, this message translates to:
  /// **'تكبيرة الإحرام'**
  String get ptOptTakbeer;

  /// No description provided for @ptOptMosque.
  ///
  /// In ar, this message translates to:
  /// **'في المسجد'**
  String get ptOptMosque;

  /// No description provided for @ptOptJamaa.
  ///
  /// In ar, this message translates to:
  /// **'جماعة'**
  String get ptOptJamaa;

  /// No description provided for @ptOptOnTime.
  ///
  /// In ar, this message translates to:
  /// **'في الوقت منفرداً'**
  String get ptOptOnTime;

  /// No description provided for @ptOptLate.
  ///
  /// In ar, this message translates to:
  /// **'بعد الوقت'**
  String get ptOptLate;

  /// No description provided for @ptOptMissed.
  ///
  /// In ar, this message translates to:
  /// **'فائتة'**
  String get ptOptMissed;

  /// No description provided for @ptClearEntry.
  ///
  /// In ar, this message translates to:
  /// **'مسح التسجيل'**
  String get ptClearEntry;

  /// No description provided for @ptPointsNum.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة'**
  String ptPointsNum(int points);

  /// No description provided for @ptDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get ptDetails;

  /// No description provided for @ptBasedOn30.
  ///
  /// In ar, this message translates to:
  /// **'بناءً على آخر ٣٠ يومًا'**
  String get ptBasedOn30;

  /// No description provided for @ptHowItWorks.
  ///
  /// In ar, this message translates to:
  /// **'كيف يعمل'**
  String get ptHowItWorks;

  /// No description provided for @ptStages.
  ///
  /// In ar, this message translates to:
  /// **'المراحل'**
  String get ptStages;

  /// No description provided for @ptStagesHint.
  ///
  /// In ar, this message translates to:
  /// **'النقاط المطلوبة لفتح كل مستوى'**
  String get ptStagesHint;

  /// No description provided for @ptContext.
  ///
  /// In ar, this message translates to:
  /// **'السياق'**
  String get ptContext;

  /// No description provided for @ptContextHint.
  ///
  /// In ar, this message translates to:
  /// **'تختلف أحكام الصلاة وتؤثر على الحساب'**
  String get ptContextHint;

  /// No description provided for @ptMan.
  ///
  /// In ar, this message translates to:
  /// **'رجل'**
  String get ptMan;

  /// No description provided for @ptWoman.
  ///
  /// In ar, this message translates to:
  /// **'امرأة'**
  String get ptWoman;

  /// No description provided for @ptPointsInApp.
  ///
  /// In ar, this message translates to:
  /// **'النقاط في التطبيق'**
  String get ptPointsInApp;

  /// No description provided for @ptOptionMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني الخيارات'**
  String get ptOptionMeanings;

  /// No description provided for @ptMultipliers.
  ///
  /// In ar, this message translates to:
  /// **'مضاعف النقاط'**
  String get ptMultipliers;

  /// No description provided for @ptMultipliersHint.
  ///
  /// In ar, this message translates to:
  /// **'جهد أكبر، نقاط أكثر'**
  String get ptMultipliersHint;

  /// No description provided for @ptPointsCount.
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة'**
  String ptPointsCount(int points);

  /// No description provided for @ptMeanTakbeer.
  ///
  /// In ar, this message translates to:
  /// **'أدركت تكبيرة الإحرام مع الإمام'**
  String get ptMeanTakbeer;

  /// No description provided for @ptMeanMosque.
  ///
  /// In ar, this message translates to:
  /// **'صليت في المسجد'**
  String get ptMeanMosque;

  /// No description provided for @ptMeanJamaa.
  ///
  /// In ar, this message translates to:
  /// **'صليت جماعة خارج المسجد'**
  String get ptMeanJamaa;

  /// No description provided for @ptMeanOnTime.
  ///
  /// In ar, this message translates to:
  /// **'صليت في وقتها منفردًا'**
  String get ptMeanOnTime;

  /// No description provided for @ptMeanLate.
  ///
  /// In ar, this message translates to:
  /// **'صليتها بعد خروج الوقت'**
  String get ptMeanLate;

  /// No description provided for @ptMeanMissed.
  ///
  /// In ar, this message translates to:
  /// **'فاتت الصلاة ولم تُصلَّ'**
  String get ptMeanMissed;

  /// No description provided for @ptOnboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'تتبع صلواتك'**
  String get ptOnboardTitle;

  /// No description provided for @ptOnboardHint.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على استمراريتك، وابنِ عادات ذات معنى، واقترب أكثر في عبادتك اليومية'**
  String get ptOnboardHint;

  /// No description provided for @ptOnboardF1T.
  ///
  /// In ar, this message translates to:
  /// **'سجل كل صلاة بضغطة'**
  String get ptOnboardF1T;

  /// No description provided for @ptOnboardF1D.
  ///
  /// In ar, this message translates to:
  /// **'بنقرة بسيطة، سجل صلاتك وابقَ على اطلاع دائم'**
  String get ptOnboardF1D;

  /// No description provided for @ptOnboardF2T.
  ///
  /// In ar, this message translates to:
  /// **'اختر كيف صليت'**
  String get ptOnboardF2T;

  /// No description provided for @ptOnboardF2D.
  ///
  /// In ar, this message translates to:
  /// **'حدد كيف صليت — تكبيرة الإحرام، جماعة، أو في الوقت'**
  String get ptOnboardF2D;

  /// No description provided for @ptOnboardF3T.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات ذكية'**
  String get ptOnboardF3T;

  /// No description provided for @ptOnboardF3D.
  ///
  /// In ar, this message translates to:
  /// **'لا تفوت صلاة — سنرسل لك تذكيرات حتى لا تنسى تسجيلها'**
  String get ptOnboardF3D;

  /// No description provided for @ptOnboardAccept.
  ///
  /// In ar, this message translates to:
  /// **'نعم، أنا موافق!'**
  String get ptOnboardAccept;

  /// No description provided for @ptOnboardLater.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get ptOnboardLater;

  /// No description provided for @ptMenuSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التتبع'**
  String get ptMenuSettings;

  /// No description provided for @ptMenuReplay.
  ///
  /// In ar, this message translates to:
  /// **'الإعداد الأولي'**
  String get ptMenuReplay;

  /// No description provided for @ptMenuWidget.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تطبيق مصغر'**
  String get ptMenuWidget;

  /// No description provided for @ptMenuDisable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل التتبع'**
  String get ptMenuDisable;

  /// No description provided for @ptMenuEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل التتبع'**
  String get ptMenuEnable;

  /// No description provided for @ptMenuClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح بيانات التتبع'**
  String get ptMenuClear;

  /// No description provided for @ptClearTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح بيانات التتبع؟'**
  String get ptClearTitle;

  /// No description provided for @ptClearHint.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف جميع الصلوات المسجلة وسلاسلك. لا يمكن التراجع.'**
  String get ptClearHint;

  /// No description provided for @ptDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get ptDelete;

  /// No description provided for @ptWidgetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة التطبيق المصغر'**
  String get ptWidgetTitle;

  /// No description provided for @ptWidgetHint.
  ///
  /// In ar, this message translates to:
  /// **'من الشاشة الرئيسية: اضغط مطولًا على مساحة فارغة، ثم التطبيقات المصغرة، ثم اختر حصن المسلم'**
  String get ptWidgetHint;

  /// No description provided for @ptPausedTitle.
  ///
  /// In ar, this message translates to:
  /// **'التتبع متوقف مؤقتًا'**
  String get ptPausedTitle;

  /// No description provided for @ptPausedHint.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحتسب الصلوات حتى تُفعّل التتبع مجددًا'**
  String get ptPausedHint;

  /// No description provided for @ptResume.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get ptResume;

  /// No description provided for @ptRemindTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بتسجيل الصلاة'**
  String get ptRemindTitle;

  /// No description provided for @ptRemindBody.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل صلاة {prayer} بعد — سجلها الآن'**
  String ptRemindBody(String prayer);

  /// No description provided for @ptRemindToggle.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات التسجيل'**
  String get ptRemindToggle;

  /// No description provided for @ptRemindHint.
  ///
  /// In ar, this message translates to:
  /// **'تذكير عند نسيان تسجيل صلاة'**
  String get ptRemindHint;

  /// No description provided for @diagFivePrayer.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الصلوات الخمس'**
  String get diagFivePrayer;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

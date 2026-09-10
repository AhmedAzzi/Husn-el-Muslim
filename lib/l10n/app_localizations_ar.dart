// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حصن المسلم';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navDua => 'دعاء';

  @override
  String get navNames => 'أسماء الله الحسنى';

  @override
  String get navRuqyah => 'الرقية الشرعية';

  @override
  String get navMasbaha => 'مسبحة';

  @override
  String get navPrayerTimes => 'مواقيت الصلاة';

  @override
  String get navMosqueMap => 'خريطة المساجد';

  @override
  String get navQibla => 'القبلة';

  @override
  String get navFajrLog => 'تتبع الصلوات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get trackCurrent => 'السلسلة الحالية';

  @override
  String get trackLongest => 'أطول سلسلة';

  @override
  String get trackToday => 'اليوم';

  @override
  String trackDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      two: '$count يومان',
      one: '$count يوم',
    );
    return '$_temp0';
  }

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String get qiblaNorth => 'ش';

  @override
  String qiblaBearing(String deg) {
    return 'اتجاه القبلة: $deg°';
  }

  @override
  String qiblaDistance(String km) {
    return 'المسافة إلى الكعبة: $km كم';
  }

  @override
  String get qiblaFacing => 'أنت متجه نحو القبلة ✓';

  @override
  String qiblaTurn(String deg, String direction) {
    return 'استدر $deg° $direction';
  }

  @override
  String get qiblaRight => 'يميناً';

  @override
  String get qiblaLeft => 'يساراً';

  @override
  String get qiblaCalibrate =>
      'حرّك الهاتف على شكل 8 لمعايرة البوصلة عند وجود تداخل مغناطيسي. يعمل دون إنترنت.';

  @override
  String get qiblaRetry => 'إعادة المحاولة';

  @override
  String get qiblaNoLocation =>
      'تعذر تحديد الموقع — فعّل GPS أو حدد موقع الصلاة أولاً';

  @override
  String get qiblaNoSensor =>
      'البوصلة غير متاحة على هذا الجهاز — اتجاه القبلة محسوب أدناه بدون بوصلة حية';

  @override
  String get awakeTitle => 'هل أنت مستيقظ؟';

  @override
  String get awakeSubtitle => 'أكملت التحدي — أكّد استيقاظك لتسجيل الفجر';

  @override
  String get iAmAwake => 'أنا مستيقظ';

  @override
  String get wellDone => 'أحسنت';

  @override
  String get wokeForFajr => 'لقد استيقظت لصلاة الفجر';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'لغة واجهة التطبيق';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'Français';

  @override
  String get diagTitle => 'التشخيص المتقدم';

  @override
  String get diagPermissions => 'حالة الأذونات';

  @override
  String get diagExactTitle => 'المنبهات الدقيقة';

  @override
  String get diagExactOk => 'مسموح — منبه الفجر يعمل بدقة';

  @override
  String get diagExactDenied => 'غير مسموح — المنبهات قد لا ترن في وقتها';

  @override
  String get diagOpenSettings => 'فتح الإعدادات';

  @override
  String get diagBatteryTitle => 'تحسين البطارية';

  @override
  String get diagBatteryOn => 'مفعّل — قد يوقف النظام المنبهات';

  @override
  String get diagBatteryOff => 'مستثنى — التطبيق يعمل بحرية';

  @override
  String get diagRequestExemption => 'طلب الاستثناء';

  @override
  String get diagOverlayTitle => 'الظهور فوق التطبيقات';

  @override
  String get diagOverlayOk => 'ممنوح — النوافذ العائمة تعمل';

  @override
  String get diagOverlayDenied => 'غير ممنوح — التنبيهات العائمة معطلة';

  @override
  String get diagRequestPermission => 'طلب الإذن';

  @override
  String get diagScheduled => 'المنبهات المجدولة';

  @override
  String get diagReadFailed => 'تعذر قراءة التشخيص';

  @override
  String get diagRescheduleAll => 'إعادة جدولة كل المنبهات';

  @override
  String get diagRescheduled => 'تمت إعادة جدولة كل المنبهات';

  @override
  String get diagRescheduleFailed => 'تعذرت إعادة الجدولة';

  @override
  String get diagTracking => 'التتبع';

  @override
  String get diagCurrent => 'الحالية';

  @override
  String get diagLongest => 'الأطول';

  @override
  String get diagTest => 'اختبار';

  @override
  String get diagTestDesc =>
      'يجدول منبه تحدي الفجر الحقيقي بعد 5 ثوانٍ (صوت + إشعار + شاشة التحدي).';

  @override
  String get diagTestScheduling => 'جارٍ الجدولة…';

  @override
  String get diagTestButton => 'تجربة منبه الفجر (5 ثوانٍ)';

  @override
  String get diagTestWillRing => 'سيرن منبه التجربة بعد 5 ثوانٍ';

  @override
  String get diagTestFailed =>
      'تعذر جدولة التجربة — تحقق من إذن المنبهات الدقيقة';

  @override
  String get chTitle => 'تحدي صلاة الفجر';

  @override
  String get chAnswerToStop => 'أجب عن السؤال لإيقاف المنبه';

  @override
  String chRemaining(int count) {
    return 'المتبقي: $count';
  }

  @override
  String get chWriteCategory => 'اكتب اسم الفئة التي ينتمي إليها هذا الذكر:';

  @override
  String get chWriteAnswerHint => 'اكتب الإجابة هنا';

  @override
  String get chVerifyAnswer => 'تحقق من الإجابة';

  @override
  String get chWrongAnswer => 'إجابة خاطئة';

  @override
  String get chTryAgain => 'حاول مرة أخرى';

  @override
  String get chLoadError => 'حدث خطأ في تحميل الأسئلة';

  @override
  String get chMathSubtitle => 'حل المسألة لإيقاف المنبه';

  @override
  String get chMathHint => 'اكتب الإجابة بالأرقام';

  @override
  String get chMemoryTitle => 'تحدي الذاكرة';

  @override
  String get chMemorySubtitle => 'اقلب البطاقات وطابق الأزواج الأربعة';

  @override
  String chMatched(int done, int total) {
    return 'المطابق: $done / $total';
  }

  @override
  String get chShakeTitle => 'هز الهاتف للاستيقاظ';

  @override
  String get chShakeSubtitle => 'هز الهاتف بقوة حتى يمتلئ الشريط';

  @override
  String get chSensorUnavailable => 'حساس الحركة غير متاح على هذا الجهاز';

  @override
  String get chSwitchToQuestions => 'التبديل إلى تحدي الأسئلة';

  @override
  String chCardHidden(int n) {
    return 'بطاقة مقلوبة $n';
  }

  @override
  String chCardShown(String face) {
    return 'بطاقة $face';
  }

  @override
  String get chPreviewBanner => 'معاينة — لن يتم تسجيل أي شيء';

  @override
  String get sheetExactTitle => 'إذن المنبهات الدقيقة مطلوب';

  @override
  String get sheetExactBody =>
      'بدون إذن المنبهات والتذكيرات من إعدادات النظام لن يرن منبه تحدي الفجر في موعده. هل تريد فتح الإعدادات لمنحه الآن؟';

  @override
  String get sheetLater => 'لاحقاً';

  @override
  String get sheetTitle => 'تحدي الاستيقاظ لصلاة الفجر';

  @override
  String get sheetSubtitle => 'منبه تفاعلي ذكي لا يتوقف إلا بعد حل الأسئلة';

  @override
  String get sheetEnable => 'تفعيل المنبه التفاعلي';

  @override
  String get sheetEnabledOn => 'المنبه مفعل وسيرن في الموعد المحدد';

  @override
  String get sheetEnabledOff => 'المنبه متوقف حالياً';

  @override
  String get sheetWarnTitle => 'تنبيه';

  @override
  String get sheetWarnBody =>
      'تم التفعيل، لكن المنبه لن يرن قبل منح إذن المنبهات الدقيقة';

  @override
  String get sheetRingTime => 'موعد رنين المنبه';

  @override
  String get sheetLastThird => 'الثلث الأخير';

  @override
  String get sheetLastThirdSub => 'تلقائياً لقيام الليل';

  @override
  String get sheetCustom => 'وقت مخصص';

  @override
  String get sheetCustomSub => 'دقائق محددة قبل الفجر';

  @override
  String get sheetBeforeFajrBy => 'الرنين قبل أذان الفجر بـ:';

  @override
  String sheetMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقائق',
      two: '$count دقيقتان',
      one: '$count دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get sheetQuestionCount => 'عدد أسئلة التحدي';

  @override
  String sheetQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أسئلة',
      two: '$count سؤالان',
      one: '$count سؤال',
    );
    return '$_temp0';
  }

  @override
  String get sheetTextMode => 'كتابة الإجابة نصياً';

  @override
  String get sheetTextModeSub =>
      'زيادة مستوى التحدي بالكتابة بدلاً من الاختيار من متعدد';

  @override
  String get sheetTestAt => 'موعد اختبار الرنين:';

  @override
  String sheetSeconds(int count) {
    return '$count ث';
  }

  @override
  String get sheetTestScheduled => 'تم جدولة اختبار المنبه';

  @override
  String sheetTestWillRing(int seconds) {
    return 'سيرن منبه تحدي الفجر فعلياً خلال $seconds ثوانٍ';
  }

  @override
  String get sheetTestFailedTitle => 'تعذر جدولة الاختبار';

  @override
  String get sheetTestFailedBody =>
      'تأكد من منح إذن المنبهات الدقيقة في إعدادات النظام';

  @override
  String get sheetTestButton => 'اختبار الرنين الفعلي (المنبه الحقيقي)';

  @override
  String get nsTitle => 'إعدادات التنبيهات والأذان';

  @override
  String get nsBatteryTitle => 'تحسين البطارية مفعل في النظام';

  @override
  String get nsBatteryBody =>
      'قد يُوقف النظام إشعارات الأذان والعد التنازلي التلقائي لتوفير الطاقة. يوصى باستثناء التطبيق من تحسين البطارية لضمان دقة التنبيهات.';

  @override
  String get nsBatteryButton => 'استثناء التطبيق من تحسين البطارية';

  @override
  String get nsPersistentSection => 'إشعارات النظام الدائمة';

  @override
  String get nsPersistent => 'إشعار شريط الحالة الدائم';

  @override
  String get nsPersistentSub =>
      'عرض التاريخ الهجري وموعد الصلاة القادمة دائماً';

  @override
  String get nsFajrEnable => 'تفعيل منبه تحدي الفجر';

  @override
  String get nsFajrEnableSub => 'منبه تفاعلي ذكي لا يتوقف إلا بعد حل أسئلة';

  @override
  String get nsChallengeType => 'نوع التحدي';

  @override
  String get nsTypeQuestions => 'أسئلة';

  @override
  String get nsTypeQuestionsSub => 'أذكار وأدعية';

  @override
  String get nsTypeMath => 'رياضيات';

  @override
  String get nsTypeMathSub => 'حساب ذهني';

  @override
  String get nsTypeMemory => 'ذاكرة';

  @override
  String get nsTypeMemorySub => 'مطابقة البطاقات';

  @override
  String get nsTypeShake => 'هز';

  @override
  String get nsTypeShakeSub => 'هز الهاتف';

  @override
  String get nsTypeRandom => 'عشوائي';

  @override
  String get nsTypeRandomSub => 'نوع مفاجئ';

  @override
  String get nsRandomPool => 'الأنواع المشمولة في العشوائي';

  @override
  String get nsShakeSensitivity => 'حساسية الهز';

  @override
  String get nsLow => 'منخفضة';

  @override
  String get nsShakeMedium => 'متوسطة';

  @override
  String get nsHigh => 'عالية';

  @override
  String get nsDifficulty => 'مستوى الصعوبة';

  @override
  String get nsEasy => 'سهل';

  @override
  String get nsDiffMedium => 'متوسط';

  @override
  String get nsHard => 'صعب';

  @override
  String get nsHardSub => 'كتابة إجبارية';

  @override
  String get nsWakeConfirm => 'تأكيد الاستيقاظ';

  @override
  String get nsWakeConfirmSub => 'بعد التحدي: هل أنت مستيقظ؟ ثم تسجيل النجاح';

  @override
  String get nsTryNow => 'تجربة التحدي الآن';

  @override
  String get nsOpenLog => 'سجل الفجر والتقدم';

  @override
  String get nsAlarmSound => 'صوت المنبه';

  @override
  String get nsSoundAdhan => 'الأذان';

  @override
  String get nsSoundAdhanSub => 'المرفق مع التطبيق';

  @override
  String get nsSoundSystem => 'نغمة النظام';

  @override
  String get nsSoundSystemSub => 'نغمة منبه الهاتف';

  @override
  String get nsSoundCustom => 'ملف مخصص';

  @override
  String get nsSoundCustomSub => 'ملف صوتي من جهازك';

  @override
  String get nsPickAudio => 'اختيار ملف صوتي';

  @override
  String get nsChangeAudio => 'تم الاختيار — تغيير الملف';

  @override
  String get nsPreviewSound => 'معاينة الصوت';

  @override
  String get nsPreviewPlaying => 'تشغيل معاينة الصوت…';

  @override
  String get nsStop => 'إيقاف';

  @override
  String get nsAlarmVolume => 'مستوى صوت المنبه';

  @override
  String get nsAlarmVibrate => 'الاهتزاز أثناء الرنين';

  @override
  String get nsAlarmLoop => 'تكرار الصوت حتى الإيقاف';

  @override
  String get nsGentleWake => 'الاستيقاظ اللطيف (تدرج الصوت)';

  @override
  String get nsInstant => 'فوري';

  @override
  String get nsExtraAlarms => 'منبهات إضافية';

  @override
  String get nsSuhoor => 'منبه السحور';

  @override
  String get nsSuhoorSub => 'وقت السحور قبل الفجر (مستقل عن أذان الفجر)';

  @override
  String get nsBeforeFajrBy => 'قبل الفجر بـ:';

  @override
  String get nsPreFajr => 'تنبيه قبل الفجر';

  @override
  String get nsPreFajrSub => 'تحذير لطيف قبل الأذان (5 / 10 / 15 دقيقة)';

  @override
  String get nsTahajjud => 'منبه التهجد';

  @override
  String get nsTahajjudSub => 'استيقاظ ليلي في الثلث الأخير أو وقت ثابت';

  @override
  String get nsTahajjudLastThird => 'الثلث الأخير (تلقائي)';

  @override
  String get nsTahajjudFixed => 'وقت ثابت';

  @override
  String get nsFajrExtra => 'إعادة التنبيه للنوم الثقيل';

  @override
  String get nsFajrExtraSub => 'إعادة تحدي الفجر بعد الفجر (+دقائق)';

  @override
  String get nsPreviewTry => 'جرّب التحدي الآن';

  @override
  String get nsBedtime => 'تذكير النوم';

  @override
  String get nsBedtimeSub => 'يساعدك على النوم مبكراً لتدرك الفجر';

  @override
  String get nsBedtimeRelative => 'نسبي إلى الفجر';

  @override
  String nsBedtimeRelativeSub(int h) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h ساعات',
      two: '$h ساعتان',
      one: '$h ساعة',
    );
    return 'الفجر − $_temp0';
  }

  @override
  String get nsSkipTonight => 'تخطي الليلة فقط';

  @override
  String get nsSkippedTonight => 'تم تخطي تذكير الليلة فقط';

  @override
  String get nsPrePrayer => 'تذكير قبل الصلاة';

  @override
  String get nsPrePrayerSub => 'تنبيه هادئ قبل كل صلاة مختارة';

  @override
  String get nsBeforePrayerBy => 'قبل الصلاة بـ:';

  @override
  String get nsPostPrayer => 'تذكير بعد الصلاة';

  @override
  String get nsPostPrayerSub => 'تذكير بالأذكار بعد كل صلاة مختارة';

  @override
  String get nsAfterPrayerBy => 'بعد الصلاة بـ:';

  @override
  String get nsAdhkarSection => 'تنبيهات أذكار الصباح والمساء';

  @override
  String get nsMorning => 'تنبيه أذكار الصباح';

  @override
  String get nsMorningSub => 'تذكير مبارك بعد صلاة الفجر بساعة واحدة';

  @override
  String get nsEvening => 'تنبيه أذكار المساء';

  @override
  String get nsEveningSub => 'تذكير مبارك بعد صلاة العصر بساعة واحدة';

  @override
  String get nsPrayerFajr => 'الفجر';

  @override
  String get nsPrayerDhuhr => 'الظهر';

  @override
  String get nsPrayerAsr => 'العصر';

  @override
  String get nsPrayerMaghrib => 'المغرب';

  @override
  String get nsPrayerIsha => 'العشاء';

  @override
  String get nsPrayerSunrise => 'الشروق';

  @override
  String get stAppearance => 'المظهر والتفضيلات العامة';

  @override
  String get stSettingsTitle => 'الإعدادات والتفضيلات';

  @override
  String get ptFajrChallengeTip => 'تحدي استيقاظ الفجر';

  @override
  String get ptLocationUpdated => 'تم تحديث الموقع بنجاح';

  @override
  String get ptLoading => 'جاري تحميل مواقيت الصلاة...';

  @override
  String get ptLoadFailed => 'تعذر جلب مواقيت الصلاة';

  @override
  String get ptLoadFailedSub => 'تأكد من تفعيل خدمات الموقع والاتصال بالإنترنت';

  @override
  String get ptLoadingShort => 'يتم التحميل...';

  @override
  String ptCorresponding(String date) {
    return ' الموافق ل $date م';
  }

  @override
  String get ptFajrChallenge => 'تحدي الفجر';

  @override
  String get ptListFailed => 'عذرًا، فشل تحميل المواقيت';

  @override
  String get ptSourceTitle => 'مصدر المواقيت';

  @override
  String get ptSourceSub => 'اختر المواقيت المحسوبة أو ابحث عن مسجد قريبك';

  @override
  String get ptCalcSub => 'حسب حساب فقهي يعتمد على موقعك';

  @override
  String get ptNearbyMosques => 'المساجد القريبة منك';

  @override
  String ptAllMosques(String country, int count) {
    return 'جميع المساجد — $country ($count)';
  }

  @override
  String get ptNoResults => 'لا توجد نتائج حالياً';

  @override
  String ptMosqueAdopted(String name) {
    return 'تم اعتماد ($name) كمسجدك الرئيسي للمواقيت';
  }

  @override
  String get ptMosqueFailed => 'تعذر تحميل مواقيت هذا المسجد، حاول مجدداً';

  @override
  String ptMeters(String m) {
    return '$m م';
  }

  @override
  String ptKm(String km) {
    return '$km كم';
  }

  @override
  String get ptIqamaAfter => 'الإقامة بعد';

  @override
  String ptPrayerAfter(String name) {
    return '$name بعد';
  }

  @override
  String get ptAyatOff => 'إيقاف نافذة الآية';

  @override
  String get ptAyatOn => 'تفعيل نافذة الآية';

  @override
  String get ctCopied => 'تم نسخ النص إلى الحافظة';

  @override
  String get ctCopy => 'نسخ';

  @override
  String get ctCopyAll => 'نسخ النص كاملاً';

  @override
  String get ctShare => 'مشاركة';

  @override
  String get ctShareAll => 'مشاركة النص كاملاً';

  @override
  String get ctClose => 'إغلاق';

  @override
  String get ctCancel => 'إلغاء';

  @override
  String get ctNoSearchResults => 'لا توجد نتائج مطابقة للبحث';

  @override
  String get ctSearch => 'بحث';

  @override
  String get ctRefresh => 'تحديث';

  @override
  String get obPermNotif => 'الإشعارات';

  @override
  String get obPermNotifSub => 'لتنبيهك بأوقات الصلاة والأذكار';

  @override
  String get obPermLocation => 'الموقع الجغرافي';

  @override
  String get obPermLocationSub => 'لتحديد مواقيت الصلاة بدقة حسب موقعك';

  @override
  String get obPermOverlay => 'العرض فوق التطبيقات';

  @override
  String get obPermOverlaySub => 'لعرض الأذكار والآيات تلقائياً على الشاشة';

  @override
  String get obWelcome => 'مرحباً بك في حصن المسلم';

  @override
  String get obSubtitle =>
      'نحتاج إلى بعض الأذونات لتعمل جميع المميزات بشكل صحيح';

  @override
  String get obSkip => 'تخطي';

  @override
  String get azEmpty => 'لا توجد نتائج';

  @override
  String get duCopied => 'تم نسخ الدعاء إلى الحافظة';

  @override
  String get duLoadFailed => 'تعذر تحميل بيانات الأدعية';

  @override
  String get duQuranSection => 'أدعية القرآن الكريم';

  @override
  String get duSunnahSection => 'أدعية السنة النبوية';

  @override
  String get duAdabSection => 'فضل وآداب الدعاء';

  @override
  String get duQuranBadge => 'قرآن كريم';

  @override
  String get duSunnahBadge => 'سنة نبوية';

  @override
  String duShareSubject(int n) {
    return 'دعاء رقم $n';
  }

  @override
  String get rqLoadFailed => 'تعذر تحميل بيانات الرقية الشرعية';

  @override
  String rqItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# فقرة / رقية',
    );
    return '$_temp0';
  }

  @override
  String get asCopiedDefault => 'تم النسخ ✿';

  @override
  String get asTapHint => 'اضغط للعرض، اضغط مطولة للنسخ';

  @override
  String get azSpeedTitle => 'سرعة العداد التلقائي';

  @override
  String get azSeconds => 'الوقت بالثانية';

  @override
  String get azAuto => 'تلقائي';

  @override
  String get azReset => 'تصفير';

  @override
  String azTimes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m مرات',
      two: '$m مرتان',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String azTimesHundred(int m) {
    return '$m مرة';
  }

  @override
  String azOfTotal(int i, int n) {
    return 'الذكر $i من $n';
  }

  @override
  String get azCopiedDhikr => 'تم نسخ الذكر إلى الحافظة';

  @override
  String get azSave => 'حفظ';

  @override
  String get azCopied => 'تم النسخ إلى الحافظة';

  @override
  String azSharePrefix(Object cat) {
    return 'من أذكار $cat';
  }

  @override
  String get msSaveFolder => 'اختر مجلد الحفظ';

  @override
  String msBackupSaved(String f) {
    return 'تم حفظ النسخة الاحتياطية: $f';
  }

  @override
  String msExportFailed(String e) {
    return 'فشل التصدير: $e';
  }

  @override
  String get msImported => 'تم استيراد البيانات بنجاح';

  @override
  String msImportFailed(String e) {
    return 'فشل الاستيراد: $e';
  }

  @override
  String get msAdded => 'تمت إضافة الذكر بنجاح!';

  @override
  String get msEdited => 'تم تعديل الذكر بنجاح!';

  @override
  String get msDeleted => 'تم حذف الذكر بنجاح!';

  @override
  String get msPickCount => 'اختر عدد التسبيحات';

  @override
  String get msCountHint => 'عدد التسبيحات (افتراضي مفتوح)';

  @override
  String get msStart => 'ابدأ';

  @override
  String get msEdit => 'تعديل';

  @override
  String get msDelete => 'حذف';

  @override
  String get msAddNew => 'إضافة ذكر جديد';

  @override
  String get msRestoreTitle => 'استعادة الأذكار الافتراضية؟';

  @override
  String get msRestoreBody =>
      'سيتم حذف جميع أذكارك الحالية واستبدالها بالقائمة الافتراضية مع السرعات الجديدة.';

  @override
  String get msRestore => 'استعادة';

  @override
  String get msHideScores => 'إخفاء النقاط';

  @override
  String get msShowScores => 'إظهار النقاط';

  @override
  String get msResetDefault => 'استعادة الافتراضي';

  @override
  String get msExport => 'تصدير البيانات';

  @override
  String get msImport => 'استيراد البيانات';

  @override
  String get msAddTitle => 'إضافة ذكر';

  @override
  String get msEditTitle => 'تعديل ذكر';

  @override
  String get msFieldDhikr => 'الذكر *';

  @override
  String get msFieldBenefit => 'الفضل';

  @override
  String get msFieldSource => 'المصدر';

  @override
  String get msFieldSpeed => 'سرعة العداد التلقائي (بالثانية)';

  @override
  String get msCounterTitle => 'عداد الذكر';

  @override
  String msVirtue(String t) {
    return 'الفضل: $t';
  }

  @override
  String msSource(String t) {
    return 'المصدر: $t';
  }

  @override
  String get msOpen => 'مفتوح';

  @override
  String get msSave => 'حفظ';

  @override
  String get stDarkMode => 'الوضع الداكن';

  @override
  String get stDarkOn => 'المظهر الليلي مفعّل لراحة العين';

  @override
  String get stDarkOff => 'المظهر النهاري الفاتح مفعّل';

  @override
  String get stDefaultHome => 'الواجهة الافتراضية';

  @override
  String get stDefaultHomeSub => 'الصفحة التي تظهر عند تشغيل التطبيق';

  @override
  String get stHomeAzkarSub => 'أذكار اليوم والليلة وحصن المسلم';

  @override
  String get stHomeMisbahaSub => 'عداد التسبيح والأذكار المخصصة';

  @override
  String get stHomePrayerSub => 'مواعيد الأذان والتنبيهات والقبلة';

  @override
  String get stHomeSet => 'تم تعيين الصفحة الرئيسية (تُطبق عند إعادة الفتح)';

  @override
  String get stLanguageTitle => 'اللغة / Language';

  @override
  String get stLanguagePicker => 'اللغة / Language / Langue';

  @override
  String get stLanguagePickerSub => 'اختر لغة واجهة التطبيق';

  @override
  String get stLangArSub => 'لغة الواجهة الافتراضية';

  @override
  String get stLangEnSub => 'Application language';

  @override
  String get stLangFrSub => 'Langue de l\'interface';

  @override
  String get stInteraction => 'المسبحة والتفاعل';

  @override
  String get stClickSound => 'صوت النقرة';

  @override
  String get stClickSoundSub => 'تشغيل صوت خفيف عند الضغط على المسبحة';

  @override
  String get stHaptic => 'الاهتزاز اللمسي';

  @override
  String get stHapticSub => 'اهتزاز الهاتف عند كل تسبيحة للتأكيد';

  @override
  String get stReminder => 'التذكير التلقائي بالأذكار';

  @override
  String get stFloatingDhikr => 'أذكار عائمة دورية';

  @override
  String get stFloatingDhikrSub =>
      'ظهور نافذة ذكر قصيرة تلقائياً فوق التطبيقات';

  @override
  String get stReminderRate => 'وتيرة التذكير';

  @override
  String get stReminderRateSub => 'الفترة الفاصلة بين كل ذكر وآخر';

  @override
  String get stEveryHour => 'كل ساعة';

  @override
  String stEveryMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m دقائق',
      two: '$m دقيقتان',
      one: '$m دقيقة',
    );
    return 'كل $_temp0';
  }

  @override
  String get stIntervalTitle => 'وتيرة التذكير التلقائي';

  @override
  String get stIntervalSub => 'المدة الزمنية بين كل ذكر عائم وآخر';

  @override
  String get stOverlayTitle => 'إذن الظهور فوق التطبيقات';

  @override
  String get stOverlayBody =>
      'ليتمكن التطبيق من عرض الأذكار القصيرة أثناء تصفحك للتطبيقات الأخرى، يحتاج إلى منح إذن الظهور فوق التطبيقات. هل تود تفعيله الآن؟';

  @override
  String get stActivateNow => 'تفعيل الآن';

  @override
  String get stHomePicker => 'الصفحة الرئيسية الافتراضية';

  @override
  String get stHomePickerSub => 'اختر الواجهة التي تبدأ مع فتح التطبيق';

  @override
  String get stPrayerData => 'مواقيت الصلاة ومصدر البيانات';

  @override
  String get stSourcePicker => 'مصدر مواقيت الصلاة';

  @override
  String get stSourcePickerSub =>
      'اختر بين مواقيت المسجد المعتمدة أو الحساب الفلكي الدقيق';

  @override
  String get stSourceMosque => 'مواقيت المسجد (أونلاين مع كاش)';

  @override
  String get stSourceMosqueSub =>
      'جلب المواقيت المعتمدة لمسجدك المحدد عبر Mawaqit وحفظها للعمل بدون إنترنت';

  @override
  String get stSourceCalc => 'مواقيت محسوبة (أوفلاين بالكامل)';

  @override
  String get stSourceCalcMode => 'مواقيت محسوبة فلكياً (أوفلاين)';

  @override
  String get stSourceCalcSub =>
      'حساب مواقيت الصلاة فلكياً بناءً على إحداثيات الموقع والمذهب الفقهي دون الحاجة للإنترنت';

  @override
  String get stSourceMosqueSet => 'تم تعيين المصدر: مواقيت المسجد';

  @override
  String get stSourceCalcSet => 'تم تعيين المصدر: مواقيت محسوبة';

  @override
  String get stCalcPicker => 'طريقة حساب مواقيت الصلاة';

  @override
  String get stCalcPickerSub =>
      'اختر الهيئة أو المجمع الفلكي المعتمد في منطقتك';

  @override
  String get stCalcSaved => 'تم حفظ طريقة الحساب وإعادة ضبط المواقيت';

  @override
  String get stAsrPicker => 'مذهب صلاة العصر';

  @override
  String get stAsrPickerSub => 'تحديد وقت دخول صلاة العصر حسب المذاهب الفقهية';

  @override
  String get stAsrShafi => 'الجمهور (شافعي، مالكي، حنبلي)';

  @override
  String get stAsrShafiSub => 'عندما يصير ظل كل شيء مثله';

  @override
  String get stAsrHanafi => 'المذهب الحنفي';

  @override
  String get stAsrHanafiSub => 'عندما يصير ظل كل شيء مثليه';

  @override
  String get stAsrSaved => 'تم حفظ مذهب العصر';

  @override
  String get stMethodMakkah => 'أم القرى (مكة المكرمة)';

  @override
  String get stMethodMakkahSub => 'المملكة العربية السعودية والخليج العربي';

  @override
  String get stMethodEgypt => 'الهيئة العامة المصرية للمساحة';

  @override
  String get stMethodEgyptSub => 'مصر، السودان، وبعض دول إفريقيا';

  @override
  String get stMethodMwl => 'رابطة العالم الإسلامي';

  @override
  String get stMethodMwlSub => 'أوروبا والشرق الأقصى وأمريكا';

  @override
  String get stMethodKarachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get stMethodKarachiSub => 'باكستان، الهند، بنغلاديش، وأفغانستان';

  @override
  String get stMethodIsna => 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';

  @override
  String get stMethodIsnaSub => 'الولايات المتحدة وكندا';

  @override
  String get stMethodKuwait => 'دولة الكويت';

  @override
  String get stMethodKuwaitSub => 'الكويت (فجر 18، عشاء 17.5)';

  @override
  String get stMethodQatar => 'دولة قطر';

  @override
  String get stMethodQatarSub => 'قطر (فجر 18، العشاء بعد المغرب بـ 90 دقيقة)';

  @override
  String get stMethodSingapore => 'سنغافورة';

  @override
  String get stMethodSingaporeSub => 'سنغافورة وماليزيا (فجر 20، عشاء 18)';

  @override
  String get stMethodTurkey => 'رئاسة الشؤون الدينية التركية';

  @override
  String get stMethodTurkeySub => 'تركيا (ديانة)';

  @override
  String get stMethodDubai => 'الإمارات والخليج (دبي)';

  @override
  String get stMethodDubaiSub => 'الإمارات ومنطقة الخليج (18.2)';

  @override
  String get stMethodMoon => 'لجنة رؤية الهلال';

  @override
  String get stMethodMoonSub => 'أمريكا الشمالية والمناطق القطبية';

  @override
  String get stCalcMethod => 'طريقة الحساب';

  @override
  String get stCalcMethodSub => 'الهيئة الفلكية المعتمدة لزوايا الفجر والعشاء';

  @override
  String get stAsrMethod => 'مذهب صلاة العصر';

  @override
  String get stAsrMethodSub => 'معيار تحديد ظل الزوال لدخول وقت العصر';

  @override
  String get stDst => 'التوقيت الصيفي';

  @override
  String get stDstSub => 'إضافة ساعة واحدة لمواقيت الصلاة تلقائياً';

  @override
  String get stManualTitle => 'تعديل مواقيت الصلاة يدوياً';

  @override
  String get stManualTileSub => 'زيادة أو إنقاص دقائق لتطابق أذان منطقتك';

  @override
  String get stReset => 'إعادة ضبط';

  @override
  String get stManualSub =>
      'يمكنك زيادة أو إنقاص دقائق محددة لكل صلاة لتطابق أذان مسجدك';

  @override
  String get stZeroMin => '0 دقيقة';

  @override
  String stMinDelta(String signed) {
    return '$signed د';
  }

  @override
  String get stManualSaved => 'تم حفظ تعديلات المواقيت بنجاح';

  @override
  String get stSaveEdits => 'حفظ التعديلات';

  @override
  String get stSave => 'حفظ';

  @override
  String get stIqamaTitle => 'هذه الإقامة (دقائق بعد الأذان)';

  @override
  String get stIqamaSub =>
      'حدد عدد دقائق الإقامة بعد الأذان لكل صلاة لعرض عد تنازلي دقيق';

  @override
  String get stIqamaTile => 'هذه الإقامة';

  @override
  String get stIqamaTileSub => 'تحديد دقائق الإقامة بعد الأذان لكل صلاة';

  @override
  String get stNoAdjust => 'بدون تعديل';

  @override
  String get stNoIqama => 'بدون إقامة';

  @override
  String stIqamaMinutes(int m) {
    return '+$m دقيقة';
  }

  @override
  String get stIqamaSaved => 'تم حفظ إعدادات الإقامة بنجاح';

  @override
  String get stHijriTitle => 'تعديل التاريخ الهجري';

  @override
  String get stHijriSub =>
      'قم بتقديم أو تأخير التاريخ الهجري يوماً أو أكثر لمطابقة الرؤية الشرعية';

  @override
  String get stHijriExact => 'التاريخ مطابق للحساب الفلكي';

  @override
  String stHijriAdjusted(String text) {
    return 'معدّل بـ ($text)';
  }

  @override
  String stHijriDays(int d) {
    return '$d يوم';
  }

  @override
  String get stAdjust => 'تعديل';

  @override
  String get stHijriSaved => 'تم حفظ تعديل التاريخ الهجري';

  @override
  String get stGpsRefreshed => 'تم تحديث الموقع ومواقيت الصلاة بنجاح';

  @override
  String get stGpsFailed => 'تعذر تحديث الموقع، يرجى التحقق من تفعيل الـ GPS';

  @override
  String get stGpsTile => 'الموقع الجغرافي (GPS)';

  @override
  String get stRefresh => 'تحديث';

  @override
  String stCoords(String lat, String lon) {
    return 'الإحداثيات: $lat, $lon';
  }

  @override
  String get stNoMosque => 'لم يتم تحديد مسجد بعد';

  @override
  String get stOpenMapChoose => 'انقر لفتح الخريطة واختيار مسجدك';

  @override
  String stCityChange(String city) {
    return 'المدينة: $city • انقر للتغيير';
  }

  @override
  String get stChangeMosque => 'تغيير المسجد';

  @override
  String get stChooseMosque => 'اختيار مسجد';

  @override
  String get stMosqueBadge => 'مواقيت المسجد';

  @override
  String get stCalcBadge => 'محسوبة';

  @override
  String get stNotifHub => 'التنبيهات والأذان';

  @override
  String get stHubTitle => 'تخصيص التنبيهات والأذان';

  @override
  String get stHubSub =>
      'الإشعار الدائم، تحدي الفجر، وتنبيهات أذكار الصباح والمساء';

  @override
  String get stAdvanced => 'متقدم';

  @override
  String get stSearchHint => 'ابحث في الإعدادات';

  @override
  String get stAdvancedMode => 'الإعدادات المتقدمة';

  @override
  String get stAdvancedModeSub =>
      'إظهار الخيارات التقنية (الفروق، الإقامة، الضبط الدقيق)';

  @override
  String get stHiddenAdvanced => 'بعض الإعدادات التقنية مخفية';

  @override
  String get stDiagTile => 'التشخيص المتقدم';

  @override
  String get stDiagTileSub => 'حالة الأذونات والمنبهات المجدولة والاختبار';

  @override
  String get stAbout => 'حول التطبيق والمشاركة';

  @override
  String get stAboutApp => 'عن حصن المسلم والإصدار';

  @override
  String stAboutAppSub(String v) {
    return 'الإصدار $v • مفتوح المصدر';
  }

  @override
  String get stOfficialSite => 'الموقع الرسمي للشيخ سعيد بن وهف';

  @override
  String get stOfficialSiteSub => 'مؤلف كتاب حصن المسلم رحمه الله';

  @override
  String get stGithub => 'المشروع على GitHub';

  @override
  String get stGithubSub => 'مساهمة في التطوير وكود المصدر';

  @override
  String get stGithubSheetSub => 'المستودع البرمجي للتطبيق على GitHub';

  @override
  String stAboutSheetLine(String v) {
    return 'الإصدار $v • تطبيق إسلامي مفتوح المصدر';
  }

  @override
  String get mmSearchHint => 'ابحث باسم المسجد أو المدينة...';

  @override
  String get mmTitle => 'خريطة المساجد';

  @override
  String get mmCloseSearch => 'إغلاق البحث';

  @override
  String get mmSearch => 'بحث';

  @override
  String get mmShowMap => 'عرض على الخريطة';

  @override
  String get mmShowList => 'عرض القائمة';

  @override
  String get mmChangeCountry => 'تغيير الدولة';

  @override
  String mmMosqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مسجد',
      two: '$count مسجداً',
      one: '$count مسجد',
    );
    return '$_temp0';
  }

  @override
  String get mmOfflineBanner =>
      'غير متصل بالإنترنت — يتم عرض المساجد المخزنة مسبقاً';

  @override
  String get mmLocateMe => 'موقعي الحالي';

  @override
  String get mmCountryPickerTitle => 'اختر الدولة لعرض المساجد';

  @override
  String get mmAdoptMosque => 'اعتماد كمسجد رئيسي';

  @override
  String get mmRetry => 'إعادة المحاولة';

  @override
  String get mmEmptyNoMosques => 'لا توجد مساجد بانتظار التحميل';

  @override
  String get mmEmptyNoResults => 'لا نتائج مطابقة';

  @override
  String get mmRefreshTimes => 'تحديث المواقيت';

  @override
  String get mmActiveMosqueBadge => 'هذا هو المسجد المعتمد حالياً في التطبيق';

  @override
  String mmDistanceKm(Object d) {
    return 'يبعد $d كم';
  }

  @override
  String mmAdoptedNow(Object name) {
    return 'تم تعيين ($name) كمسجدك الرئيسي للمواقيت';
  }

  @override
  String get mmActiveMosque => 'المسجد المعتمد';

  @override
  String get mmAdoptThis => 'اعتماد هذا المسجد للمواقيت';

  @override
  String get mmDirections => 'الاتجاهات في الخريطة';

  @override
  String get mmDirectionsFailed => 'تعذر فتح الاتجاهات. لا يوجد تطبيق خرائط.';

  @override
  String get mmShare => 'مشاركة المواقيت';

  @override
  String mmJumua(Object t) {
    return 'الجمعة: $t';
  }

  @override
  String get mmFriday => 'صلاة الجمعة';

  @override
  String get mmAppName => 'تطبيق حصن المسلم';

  @override
  String mmPrayerTimesFor(Object city, Object name) {
    return 'مواقيت الصلاة لـ $name ($city):';
  }

  @override
  String get mmErrorNetwork =>
      'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get mmErrorParsing =>
      'خطأ في قراءة بيانات الخادم. تم تحديث بيانات المساجد، يرجى المحاولة لاحقاً.';

  @override
  String get mmErrorNotFound => 'لم يتم العثور على بيانات المساجد لهذه الدولة.';

  @override
  String get mmErrorServer => 'خطأ في خادم مواقيت. يرجى المحاولة لاحقاً.';

  @override
  String get mmErrorTimeout =>
      'انتهت مهلة الاتصال بالخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get mmErrorGeneral =>
      'تعذّر تحميل قائمة المساجد. تأكد من الاتصال بالإنترنت.';

  @override
  String get mmScheduleErrorNetwork =>
      'تعذر الاتصال بالخادم لتحميل مواقيت المسجد.';

  @override
  String get mmScheduleErrorParsing =>
      'خطأ في قراءة مواقيت المسجد. قد يكون تنسيق البيانات قد تغير.';

  @override
  String get mmScheduleErrorNotFound => 'لم يتم العثور على مواقيت لهذا المسجد.';

  @override
  String get mmScheduleErrorServer =>
      'خطأ في خادم مواقيت. يرجى المحاولة لاحقاً.';

  @override
  String get mmScheduleErrorTimeout => 'انتهت مهلة الاتصال عند تحميل المواقيت.';

  @override
  String get mmScheduleErrorGeneral => 'تعذّر تحميل مواقيت هذا المسجد.';

  @override
  String get nsExtraAdhkarSection => 'أذكار إضافية';

  @override
  String get nsWakeupAdhkar => 'تنبيه أذكار الاستيقاظ';

  @override
  String get nsWakeupAdhkarSub =>
      'تذكير مبارك بأذكار الاستيقاظ من النوم عند الفجر';

  @override
  String get nsSleepAdhkar => 'تنبيه أذكار النوم';

  @override
  String get nsSleepAdhkarSub => 'تذكير مبارك بأذكار النوم قبل موعد نومك';

  @override
  String get nsFridayKahf => 'تذكير سورة الكهف يوم الجمعة';

  @override
  String get nsFridayKahfSub =>
      'تذكير صباح كل جمعة بقراءة سورة الكهف نوراً بين الجمعتين';

  @override
  String get nsFridayKahfTitle => 'سورة الكهف';

  @override
  String get nsFridayKahfBody =>
      'لا تنس قراءة سورة الكهف اليوم — نور ما بين الجمعتين';

  @override
  String get nsDndSection => 'الوضع الصامت التلقائي (DND)';

  @override
  String get nsDndTitle => 'كتم الهاتف أثناء الصلاة';

  @override
  String get nsDndSub =>
      'تفعيل عدم الإزعاج تلقائياً عند دخول وقت الصلاة لمنع الرنين في المسجد';

  @override
  String get nsDndDuration => 'مدة الكتم بعد الأذان';

  @override
  String get nsDndPermNeeded => 'يتطلب إذن الوصول إلى سياسة عدم الإزعاج';

  @override
  String get nsDndPermGrant => 'منح إذن عدم الإزعاج';

  @override
  String nsDndMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m دقائق',
      two: '$m دقيقتان',
      one: '$m دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get diagDndTitle => 'سياسة عدم الإزعاج (DND)';

  @override
  String get diagDndOk => 'ممنوح — الكتم التلقائي أثناء الصلاة متاح';

  @override
  String get diagDndDenied =>
      'غير ممنوح — التطبيق لا يستطيع كتم الهاتف تلقائياً';

  @override
  String get ptTrackerTitle => 'تتبع الصلوات';

  @override
  String ptLevelTitle(int level) {
    return 'المستوى $level';
  }

  @override
  String get ptDailyGoal => 'الهدف اليومي';

  @override
  String get ptEdit => 'تعديل';

  @override
  String get ptGoalToday => 'هدف اليوم';

  @override
  String get ptOverview => 'نظرة عامة على الصلاة';

  @override
  String get ptLast30Days => 'آخر ٣٠ يوماً';

  @override
  String get ptEmptyTitle => 'لا توجد بيانات صلاة مسجلة بعد';

  @override
  String get ptEmptyHint => 'ابدأ بتسجيل صلواتك لرؤية النظرة العامة هنا';

  @override
  String get ptGoalDialogTitle => 'هدفك اليومي';

  @override
  String get ptGoalDialogHint => 'عدد الصلوات المطلوبة يومياً';

  @override
  String get ptSave => 'حفظ';

  @override
  String get ptTotalPrayers => 'مجموع الصلوات';

  @override
  String get ptOnTimeRate => 'نسبة الالتزام';

  @override
  String get ptTotalPoints => 'مجموع النقاط';

  @override
  String get ptHowPrayed => 'كيف صليت؟';

  @override
  String get ptOptTakbeer => 'تكبيرة الإحرام';

  @override
  String get ptOptMosque => 'في المسجد';

  @override
  String get ptOptJamaa => 'جماعة';

  @override
  String get ptOptOnTime => 'في الوقت منفرداً';

  @override
  String get ptOptLate => 'بعد الوقت';

  @override
  String get ptOptMissed => 'فائتة';

  @override
  String get ptClearEntry => 'مسح التسجيل';

  @override
  String ptPointsNum(int points) {
    return '+$points نقطة';
  }

  @override
  String get ptDetails => 'التفاصيل';

  @override
  String get ptBasedOn30 => 'بناءً على آخر ٣٠ يومًا';

  @override
  String get ptHowItWorks => 'كيف يعمل';

  @override
  String get ptStages => 'المراحل';

  @override
  String get ptStagesHint => 'النقاط المطلوبة لفتح كل مستوى';

  @override
  String get ptContext => 'السياق';

  @override
  String get ptContextHint => 'تختلف أحكام الصلاة وتؤثر على الحساب';

  @override
  String get ptMan => 'رجل';

  @override
  String get ptWoman => 'امرأة';

  @override
  String get ptPointsInApp => 'النقاط في التطبيق';

  @override
  String get ptOptionMeanings => 'معاني الخيارات';

  @override
  String get ptMultipliers => 'مضاعف النقاط';

  @override
  String get ptMultipliersHint => 'جهد أكبر، نقاط أكثر';

  @override
  String ptPointsCount(int points) {
    return '$points نقطة';
  }

  @override
  String get ptMeanTakbeer => 'أدركت تكبيرة الإحرام مع الإمام';

  @override
  String get ptMeanMosque => 'صليت في المسجد';

  @override
  String get ptMeanJamaa => 'صليت جماعة خارج المسجد';

  @override
  String get ptMeanOnTime => 'صليت في وقتها منفردًا';

  @override
  String get ptMeanLate => 'صليتها بعد خروج الوقت';

  @override
  String get ptMeanMissed => 'فاتت الصلاة ولم تُصلَّ';

  @override
  String get ptOnboardTitle => 'تتبع صلواتك';

  @override
  String get ptOnboardHint =>
      'حافظ على استمراريتك، وابنِ عادات ذات معنى، واقترب أكثر في عبادتك اليومية';

  @override
  String get ptOnboardF1T => 'سجل كل صلاة بضغطة';

  @override
  String get ptOnboardF1D => 'بنقرة بسيطة، سجل صلاتك وابقَ على اطلاع دائم';

  @override
  String get ptOnboardF2T => 'اختر كيف صليت';

  @override
  String get ptOnboardF2D =>
      'حدد كيف صليت — تكبيرة الإحرام، جماعة، أو في الوقت';

  @override
  String get ptOnboardF3T => 'إشعارات ذكية';

  @override
  String get ptOnboardF3D =>
      'لا تفوت صلاة — سنرسل لك تذكيرات حتى لا تنسى تسجيلها';

  @override
  String get ptOnboardAccept => 'نعم، أنا موافق!';

  @override
  String get ptOnboardLater => 'ليس الآن';

  @override
  String get ptMenuSettings => 'إعدادات التتبع';

  @override
  String get ptMenuReplay => 'الإعداد الأولي';

  @override
  String get ptMenuWidget => 'إضافة تطبيق مصغر';

  @override
  String get ptMenuDisable => 'تعطيل التتبع';

  @override
  String get ptMenuEnable => 'تفعيل التتبع';

  @override
  String get ptMenuClear => 'مسح بيانات التتبع';

  @override
  String get ptClearTitle => 'مسح بيانات التتبع؟';

  @override
  String get ptClearHint =>
      'سيتم حذف جميع الصلوات المسجلة وسلاسلك. لا يمكن التراجع.';

  @override
  String get ptDelete => 'حذف';

  @override
  String get ptWidgetTitle => 'إضافة التطبيق المصغر';

  @override
  String get ptWidgetHint =>
      'من الشاشة الرئيسية: اضغط مطولًا على مساحة فارغة، ثم التطبيقات المصغرة، ثم اختر حصن المسلم';

  @override
  String get ptPausedTitle => 'التتبع متوقف مؤقتًا';

  @override
  String get ptPausedHint => 'لن تُحتسب الصلوات حتى تُفعّل التتبع مجددًا';

  @override
  String get ptResume => 'تفعيل';

  @override
  String get ptRemindTitle => 'تذكير بتسجيل الصلاة';

  @override
  String ptRemindBody(String prayer) {
    return 'لم تسجل صلاة $prayer بعد — سجلها الآن';
  }

  @override
  String get ptRemindToggle => 'تذكيرات التسجيل';

  @override
  String get ptRemindHint => 'تذكير عند نسيان تسجيل صلاة';

  @override
  String get diagFivePrayer => 'تتبع الصلوات الخمس';
}

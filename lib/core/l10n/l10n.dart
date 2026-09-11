/// Lightweight localization used across the khatma ("ختمة") feature.
///
/// Quran Arabic text is never routed through here — only app UI strings are
/// translated. Arabic, English and French are supported.
///
/// The UI language is NOT a khatma setting: it always follows Husn-el-Muslim's
/// global `app_language` preference (see [khatmaLang]).
library;

import '../services/shared_prefs_cache.dart';

/// Current khatma UI language: Husn's global app language, 'ar' fallback.
String khatmaLang() {
  try {
    final code = SharedPrefsCache.instance.getString('app_language');
    if (code == 'en') return 'en';
    if (code == 'fr') return 'fr';
    return 'ar';
  } catch (_) {
    return 'ar';
  }
}

class L10n {
  L10n(this._lang);
  final String _lang;

  static const supported = ['ar', 'en', 'fr'];

  static L10n of(String lang) => L10n(lang);

  String get _l => _lang;

  String t(String key) => _map[_l]?[key] ?? _map['ar']![key] ?? key;

  static const _map = <String, Map<String, String>>{
    'ar': {
      'app_name': 'ختمة',
      'tagline': 'كل فتح لهاتفك فرصة للقرآن',
      'continue': 'متابعة القراءة',
      'done_reading': 'تمت القراءة',
      'later': 'لاحقًا',
      'previous': 'السابق',
      'next': 'التالي',
      'listen': 'استماع',
      'tafsir': 'التفسير',
      'home': 'الرئيسية',
      'quran': 'المصحف',
      'settings': 'الإعدادات',
      'statistics': 'الإحصائيات',
      'khatma': 'الختمة',
      'audio': 'الصوتيات',
      'start_khatma': 'ابدأ ختمة',
      'choose_start': 'اختر مكان البدء',
      'surah': 'السورة',
      'ayah': 'الآية',
      'start': 'ابدأ',
      'today_progress': 'إحصائيات اليوم',
      'yesterday': 'أمس',
      'today': 'اليوم',
      'total_verses': 'إجمالي الآيات',
      'daily_goal': 'الهدف اليومي',
      'current_khatma': 'الختمة الحالية',
      'no_khatma': 'لا توجد ختمة',
      'green_word': 'لم تقرأ شيئًا بعد',
      'read': 'قراءة',
      'minutes': 'دقيقة',
      'streak': 'سلسلة',
      'overlay_hint': 'عرض الآية العائمة',
      'overlay_lock_hint':
          'الآية ستظهر تلقائيًا فوق التطبيقات عند فتح الهاتف، وستبقى حتى تضغط ✓ أو ◷',
      'overlay_preview_failed': 'ابدأ ختمة أولًا لتتمكن من العرض',
      'phone_experience': 'تجربة فتح الهاتف',
      'quiet_hours': 'ساعات الراحة',
      'language': 'اللغة',
      'narration': 'الرواية',
      'reciter': 'القارئ',
      'font_size': 'حجم الخط',
      'tajweed': 'ألوان التجويد',
      'translation': 'الترجمة',
      'onboarding_1': 'اجعل كل فتح لهاتفك فرصة للقرآن',
      'onboarding_2': 'تابع من حيث توقفت',
      'onboarding_3': 'استمع إلى قارئك المفضل',
      'onboarding_4': 'تابع إنجازك',
      'welcome': 'السلام عليكم',
      'audio_cache': 'ذاكرة الصوتيات',
      'clear_cache': 'مسح الذاكرة',
      'password_privacy': 'خصوصيتك',
    },
    'en': {
      'app_name': 'Khatmah',
      'tagline': 'Make every phone unlock a chance to read the Quran',
      'continue': 'Continue reading',
      'done_reading': 'Done reading',
      'later': 'Later',
      'previous': 'Previous',
      'next': 'Next',
      'listen': 'Listen',
      'tafsir': 'Tafsir',
      'home': 'Home',
      'quran': 'Quran',
      'settings': 'Settings',
      'statistics': 'Statistics',
      'khatma': 'Khatma',
      'audio': 'Audio',
      'start_khatma': 'Start a Khatma',
      'choose_start': 'Choose where to start',
      'surah': 'Surah',
      'ayah': 'Ayah',
      'start': 'Start',
      'today_progress': "Today's progress",
      'yesterday': 'Yesterday',
      'today': 'Today',
      'total_verses': 'Total verses',
      'daily_goal': 'Daily goal',
      'current_khatma': 'Current khatma',
      'no_khatma': 'No khatma yet',
      'green_word': "You haven't read anything yet",
      'read': 'read',
      'minutes': 'minutes',
      'streak': 'Streak',
      'overlay_hint': 'Show floating ayah',
      'overlay_lock_hint':
          'The ayah appears above other apps when you unlock the phone, and stays until you press ✓ or ◷',
      'overlay_preview_failed': 'Start a khatma first to preview',
      'phone_experience': 'Phone-open experience',
      'quiet_hours': 'Quiet hours',
      'language': 'Language',
      'narration': 'Narration',
      'reciter': 'Reciter',
      'font_size': 'Font size',
      'tajweed': 'Tajweed colors',
      'translation': 'Translation',
      'onboarding_1': 'Make every phone unlock a chance to read the Quran',
      'onboarding_2': 'Continue from where you left off',
      'onboarding_3': 'Listen to your favorite reciter',
      'onboarding_4': 'Follow your progress',
      'welcome': 'Peace be upon you',
      'audio_cache': 'Audio cache',
      'clear_cache': 'Clear cache',
      'password_privacy': 'Your privacy',
    },
    'fr': {
      'app_name': 'Khatmah',
      'tagline':
          'Faites de chaque ouverture du téléphone une occasion de lire le Coran',
      'continue': 'Continuer la lecture',
      'done_reading': 'Lecture terminée',
      'later': 'Plus tard',
      'previous': 'Précédent',
      'next': 'Suivant',
      'listen': 'Écouter',
      'tafsir': 'Tafsir',
      'home': 'Accueil',
      'quran': 'Coran',
      'settings': 'Paramètres',
      'statistics': 'Statistiques',
      'khatma': 'Khatma',
      'audio': 'Audio',
      'start_khatma': 'Commencer une Khatma',
      'choose_start': 'Choisir où commencer',
      'surah': 'Sourate',
      'ayah': 'Ayah',
      'start': 'Commencer',
      'today_progress': 'Progrès du jour',
      'yesterday': 'Hier',
      'today': "Aujourd'hui",
      'total_verses': 'Total des versets',
      'daily_goal': 'Objectif quotidien',
      'current_khatma': 'Khatma actuelle',
      'no_khatma': 'Pas encore de khatma',
      'green_word': "Vous n'avez rien lu pour l'instant",
      'read': 'lus',
      'minutes': 'minutes',
      'streak': 'Série',
      'overlay_hint': 'Afficher l’ayah flottante',
      'overlay_lock_hint':
          'L’ayah apparaîtra au-dessus des autres applications au déverrouillage du téléphone et restera jusqu’à ce que vous appuyiez sur ✓ ou ◷',
      'overlay_preview_failed': 'Commencez une khatma pour prévisualiser',
      'phone_experience': 'Expérience à l’ouverture',
      'quiet_hours': 'Heures de repos',
      'language': 'Langue',
      'narration': 'Récitation',
      'reciter': 'Récitateur',
      'font_size': 'Taille de police',
      'tajweed': 'Couleurs de tajwid',
      'translation': 'Traduction',
      'onboarding_1':
          'Faites de chaque ouverture du téléphone une occasion de lire le Coran',
      'onboarding_2': 'Reprenez là où vous vous êtes arrêté',
      'onboarding_3': 'Écoutez votre récitateur préféré',
      'onboarding_4': 'Suivez vos progrès',
      'welcome': 'Que la paix soit sur vous',
      'audio_cache': 'Cache audio',
      'clear_cache': 'Vider le cache',
      'password_privacy': 'Votre vie privée',
    },
  };
}

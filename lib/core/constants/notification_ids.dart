/// Named constants for notification IDs and payloads to avoid scattering
/// magic numbers/strings across the app. Values are unchanged from the
/// original literals so behaviour is identical.
class NotificationIds {
  const NotificationIds._();

  /// Unique request ID for the morning adhkar (أذكار الصباح) notification.
  static const int morningAdhkar = 100;

  /// Unique request ID for the evening adhkar (أذكار المساء) notification.
  static const int eveningAdhkar = 101;

  /// Unique request ID for the wake-up adhkar (أذكار الاستيقاظ) notification.
  static const int wakeupAdhkar = 102;

  /// Unique request ID for the sleep adhkar (أذكار النوم) notification.
  static const int sleepAdhkar = 103;

  /// Unique request ID for the Friday Surah Al-Kahf reminder notification.
  static const int fridayKahf = 104;

  /// Payload identifying the morning adhkar notification tap.
  static const String morningAdhkarPayload = 'Morning_Adhkar';

  /// Payload identifying the evening adhkar notification tap.
  static const String eveningAdhkarPayload = 'Evening_Adhkar';

  /// Payload identifying the wake-up adhkar notification tap.
  static const String wakeupAdhkarPayload = 'Wakeup_Adhkar';

  /// Payload identifying the sleep adhkar notification tap.
  static const String sleepAdhkarPayload = 'Sleep_Adhkar';

  /// Payload identifying the Friday Surah Al-Kahf notification tap.
  static const String fridayKahfPayload = 'Friday_Kahf';

  /// Base ID for the 5-prayer logging reminders (Fajr..Isha → 200..204).
  /// One-shot schedules owned by PrayerReminderService; never daily-repeat.
  static const int trackerLogBase = 200;

  /// Payload identifying a tracker logging-reminder tap (opens the tracker).
  static const String trackerLogPayload = 'PrayerTrack_Log';

  /// Internal marker index used by the controller to deduplicate the Fajr
  /// Challenge trigger within a single day (never leaves the app).
  static const int fajrChallengeIndex = 9999;
}


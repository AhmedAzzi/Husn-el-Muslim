/// Named constants for notification IDs and payloads to avoid scattering
/// magic numbers/strings across the app. Values are unchanged from the
/// original literals so behaviour is identical.
class NotificationIds {
  const NotificationIds._();

  /// Unique request ID for the morning adhkar (أذكار الصباح) notification.
  static const int morningAdhkar = 100;

  /// Unique request ID for the evening adhkar (أذكار المساء) notification.
  static const int eveningAdhkar = 101;

  /// Payload identifying the morning adhkar notification tap.
  static const String morningAdhkarPayload = 'Morning_Adhkar';

  /// Payload identifying the evening adhkar notification tap.
  static const String eveningAdhkarPayload = 'Evening_Adhkar';

  /// Internal marker index used by the controller to deduplicate the Fajr
  /// Challenge trigger within a single day (never leaves the app).
  static const int fajrChallengeIndex = 9999;
}

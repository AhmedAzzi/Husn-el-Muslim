import 'package:shared_preferences/shared_preferences.dart';

/// Singleton cache for SharedPreferences to avoid redundant
/// platform-channel calls throughout the app.
///
/// Call [init] once during app startup, then use [instance] everywhere.
class SharedPrefsCache {
  SharedPrefsCache._();

  static SharedPreferences? _prefs;

  /// Must be called once before any access to [instance].
  static void init(SharedPreferences prefs) => _prefs = prefs;

  /// Returns the cached instance. Throws if [init] hasn't been called.
  static SharedPreferences get instance {
    assert(_prefs != null,
        'SharedPrefsCache.init() must be called before accessing instance');
    return _prefs!;
  }

  /// Safe async getter that falls back to fetching if not yet initialized.
  /// Useful in background isolates / Workmanager callbacks.
  static Future<SharedPreferences> get instanceAsync async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';

/// Shared primitives for the tracking repositories (prayer/sunnah/worship/
/// fajr). Extracted byte-for-byte from the per-repo clones; no behavior
/// change (same fallback chain, same local-midnight truncation).
Future<SharedPreferences> trackingPrefs() async {
  try {
    return SharedPrefsCache.instance;
  } catch (_) {
    return SharedPreferences.getInstance();
  }
}

/// Truncates [d] to local midnight. Replaces the `_dayOnly` helper and the
/// inline `DateTime(x.year, x.month, x.day)` copies.
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

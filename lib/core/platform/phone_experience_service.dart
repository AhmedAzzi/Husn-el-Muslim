import 'package:flutter/services.dart';

/// Centralizes all Android "phone-use" capability behind one interface so
/// Flutter code never calls platform APIs directly.
///
/// The original Nakhtem concept presented the current ayah when the phone was
/// unlocked. Modern Android **does not** allow an app to detect "unlock", pin a
/// lock screen, or impersonate system UI, and we must never try. Instead we
/// expose the strongest *compliant* capabilities:
///
///   * checking Android version,
///   * overlay (SYSTEM_ALERT_WINDOW) permission — the closest to a "peek"
///     experience, only when the user explicitly enables it,
///   * a notification-driven fallback (see [showAyahNotification]).
///
/// All capability methods degrade gracefully when unsupported or denied.
class PhoneExperienceService {
  PhoneExperienceService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('khatmah/phone_experience'),
        _actions = const EventChannel('khatmah/overlay_actions');

  final MethodChannel _channel;
  final EventChannel _actions;

  /// Called (on the platform thread) when the user acts on the native overlay:
  /// `completed` (✔️) or `later` (✕). The ayah that was shown is included.
  void Function(String action, {int globalAyah, int surah, int ayah})?
      onOverlayAction;

  /// Starts listening for native overlay actions. Call once at startup.
  /// No-op when the native overlay plugin isn't bundled (e.g. Husn-el-Muslim
  /// without the khatmah overlay channels): the [MissingPluginException]
  /// raised while activating the broadcast stream is swallowed so startup
  /// stays clean and the khatma tracker keeps working without the overlay.
  void listenForOverlayActions() {
    try {
      _actions.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            final action = event['action']?.toString() ?? '';
            final g = (event['globalAyah'] as num?)?.toInt() ?? 0;
            final s = (event['surah'] as num?)?.toInt() ?? 0;
            final a = (event['ayah'] as num?)?.toInt() ?? 0;
            onOverlayAction?.call(action, globalAyah: g, surah: s, ayah: a);
          }
        },
        // Native side absent or stream activation failed — stay quiet.
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // MissingPluginException and friends: overlay simply unavailable.
    }
  }

  bool _logicallySupported = true;

  /// Whether the platform bridge reported a fatal error last call.
  bool get supported => _logicallySupported;

  Future<int> androidVersion() async {
    try {
      final v = await _channel.invokeMethod<int>('getAndroidVersion');
      _logicallySupported = true;
      return v ?? 0;
    } catch (_) {
      _logicallySupported = false;
      return 0;
    }
  }

  Future<bool> checkPhoneUseCapability() async {
    try {
      final r = await _channel.invokeMethod<bool>('checkPhoneUseCapability');
      _logicallySupported = true;
      return r ?? false;
    } catch (_) {
      _logicallySupported = false;
      return false;
    }
  }

  Future<bool> isOverlayPermissionGranted() async {
    try {
      final r = await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final r =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "Display over other apps" settings screen.
  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod<void>('openOverlaySettings');
    } catch (_) {
      // ignored
    }
  }

  /// Asks the platform to start a foreground service that draws the ayah as an
  /// always-on-top overlay ("Display over other apps"). Returns false when the
  /// overlay permission has not been granted.
  ///
  /// [globalAyah] is the canonical 1-based global index of the ayah shown, so
  /// a ✓ action can advance the reading position correctly. [meta] is the
  /// reference-style location line (e.g. "(نوح - 4 / 28)"), [tafsir] optional
  /// green explanation text (empty = hidden; never fabricated). [audioUrl] is
  /// the per-ayah stream built from the selected reciter, with mirror
  /// fallbacks newline-joined after the primary URL (empty = the native
  /// play button toasts instead of failing silently). [prev]/[next]
  /// are optional neighbour bundles (same keys) enabling overlay navigation.
  Future<bool> showAyahOverlay({
    required String title,
    required String body,
    required int globalAyah,
    required int surah,
    required int ayah,
    String meta = '',
    String tafsir = '',
    String audioUrl = '',
    Map<String, Object?>? prev,
    Map<String, Object?>? next,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('showAyahOverlay', {
        'title': title,
        'body': body,
        'globalAyah': globalAyah,
        'surah': surah,
        'ayah': ayah,
        'meta': meta,
        'tafsir': tafsir,
        'audioUrl': audioUrl,
        'prev': prev,
        'next': next,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Writes the ayah + neighbours + enabled flag to the native cache so the
  /// unlock receiver can draw the overlay while the Dart isolate is paused
  /// (screen off). Best effort — never throws.
  Future<void> cacheOverlayAyah({
    required bool enabled,
    String title = '',
    String body = '',
    String meta = '',
    String tafsir = '',
    String audioUrl = '',
    int globalAyah = 0,
    int surah = 0,
    int ayah = 0,
    Map<String, Object?>? prev,
    Map<String, Object?>? next,
  }) async {
    try {
      await _channel.invokeMethod<void>('cacheOverlayAyah', {
        'enabled': enabled,
        'title': title,
        'body': body,
        'meta': meta,
        'tafsir': tafsir,
        'audioUrl': audioUrl,
        'globalAyah': globalAyah,
        'surah': surah,
        'ayah': ayah,
        'prev': prev,
        'next': next,
      });
    } catch (_) {
      // ignored
    }
  }

  /// Returns a natively-persisted ✓ completion (global ayah index) and clears
  /// it. Used to reconcile reads tapped while the engine was dead. 0 = none.
  Future<int> consumePendingCompletion() async {
    try {
      final v = await _channel.invokeMethod<int>('consumePendingCompletion');
      return v ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Stops/dismisses any currently-displayed ayah overlay.
  Future<void> dismissAyahOverlay() async {
    try {
      await _channel.invokeMethod<void>('dismissAyahOverlay');
    } catch (_) {
      // ignored
    }
  }

  /// Ask the platform to request notification permission (Android 13+).
  Future<bool> requestNotificationPermission() async {
    try {
      final r =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows a heads-up "time for Quran" notification; tapping opens the app.
  Future<bool> showAyahNotification({
    required String title,
    required String body,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('showAyahNotification', {
        'title': title,
        'body': body,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Dismiss any currently-visible ayah surface.
  Future<void> dismissAyahExperience() async {
    try {
      await _channel.invokeMethod<void>('dismissAyahExperience');
    } catch (_) {
      // ignored
    }
  }

  bool quietHoursActive({required int startMinutes, required int endMinutes, DateTime? now}) {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    if (startMinutes == endMinutes) return false;
    if (startMinutes < endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }
    // range wraps past midnight
    return minutes >= startMinutes || minutes < endMinutes;
  }
}

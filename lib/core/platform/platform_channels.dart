import 'package:flutter/services.dart';

/// Single home for native platform channel names shared with the Kotlin
/// layer (`MainActivity`, `AyahOverlayService`). A typo in any of these
/// literals fails silently as `MissingPluginException`, so they must never
/// be duplicated as raw strings at call sites.
class PlatformChannels {
  const PlatformChannels._();

  /// Prayer notifications, exact alarms, overlay permission, DND.
  /// Handled in `MainActivity` (`prayer_notification` handler).
  static const MethodChannel prayerNotification =
      MethodChannel('com.ahmed.hisnelmuslim/prayer_notification');

  /// Battery-optimization exemption. Handled in `MainActivity`.
  static const MethodChannel batteryOptimization =
      MethodChannel('com.ahmed.hisnelmuslim/battery_optimization');

  /// Max-volume lock while the Fajr challenge rings. Handled in `MainActivity`.
  static const MethodChannel volumeLock =
      MethodChannel('com.ahmed.hisnelmuslim/volume_lock');

  /// One-shot location request. Handled in `MainActivity`.
  static const MethodChannel location =
      MethodChannel('com.ahmed.hisnelmuslim/location');

  /// Khatma floating-ayah overlay. Handled in `MainActivity`.
  static const MethodChannel phoneExperience =
      MethodChannel('khatmah/phone_experience');

  /// Overlay button actions (done/later/play/help) from native.
  /// Served by `AyahOverlayService`.
  static const EventChannel overlayActions =
      EventChannel('khatmah/overlay_actions');
}

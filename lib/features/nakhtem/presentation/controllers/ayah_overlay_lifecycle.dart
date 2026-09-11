import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/platform/phone_experience_service.dart';
import 'nakhtem_controller.dart';

/// Coordinates the unlock overlay with the app lifecycle WITHOUT ever showing
/// anything itself.
///
/// Trigger ownership (strict separation):
///   * Showing is owned SOLELY by the native [ScreenUnlockReceiver] gate:
///     genuine SCREEN_OFF → USER_PRESENT cycles only. App backgrounding,
///     app switching, Home press, touch, timers, resume, process recreation
///     and boot NEVER show the overlay.
///   * This observer only (a) forwards native overlay button actions to
///     [NakhtemController.handleOverlayAction], and (b) on every resume
///     reconciles a ✓ tap persisted while the engine was away and refreshes
///     the native unlock cache. Resume itself never triggers an overlay.
class AyahOverlayLifecycleObserver with WidgetsBindingObserver {
  AyahOverlayLifecycleObserver();

  /// Starts listening to the native overlay actions. Call once at startup,
  /// after the controller and settings are registered.
  void wire(PhoneExperienceService service) {
    service.listenForOverlayActions();
    service.onOverlayAction = (action,
        {int globalAyah = 0, int surah = 0, int ayah = 0}) {
      Get.find<NakhtemController>().handleOverlayAction(
        action,
        globalAyah: globalAyah,
        surah: surah,
        ayah: ayah,
      );
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume (including return-to-app) must NOT show the overlay (Cases B–D).
    // Only reconcile + re-cache so the NEXT genuine unlock shows the right
    // ayah.
    if (state == AppLifecycleState.resumed) {
      Get.find<NakhtemController>().reconcilePendingCompletion();
    }
  }
}

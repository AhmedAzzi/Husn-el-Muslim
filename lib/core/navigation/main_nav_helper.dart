import 'package:get/get.dart';
import 'package:small_husn_muslim/core/navigation/main_destinations.dart';
import 'package:small_husn_muslim/core/navigation/main_nav_controller.dart';

/// Helper for code paths that need to land on a main section from anywhere
/// (notification taps, native alarm callbacks, section-to-section jumps).
///
/// When the shell controller exists, the destination is switched in place —
/// no extra route is pushed. Otherwise (cold start before the shell is up)
/// the call is a no-op and the caller falls back to a direct push.
class MainNavHelper {
  MainNavHelper._();

  static void goTo(MainDestination destination) {
    if (Get.isRegistered<MainNavController>()) {
      // Pop any detail screens stacked above the shell so the section
      // switch is visible, then switch the IndexedStack page.
      if (Get.context != null) {
        Get.until((route) => route.isFirst);
      }
      Get.find<MainNavController>().goTo(destination);
    }
  }

  static void goToMawaqit() => goTo(MainDestination.mawaqit);

  static void goToMosqueMap() => goTo(MainDestination.mosqueMap);

  static void goToTracking() => goTo(MainDestination.tracking);

  static void goToSettings() => goTo(MainDestination.settings);

  static bool get isShellReady => Get.isRegistered<MainNavController>();
}

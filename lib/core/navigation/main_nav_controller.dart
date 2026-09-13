import 'package:get/get.dart';
import 'package:small_husn_muslim/core/navigation/main_destinations.dart';

/// Single source of truth for top-level navigation.
///
/// The app shows one [MainShell] route; switching sections only changes
/// [destination] (rendered as an IndexedStack), so no navigation-stack
/// history is created when moving between main sections and each visited
/// section keeps its state. Detail screens keep using `Get.to` / Back on top
/// of the shell.
class MainNavController extends GetxController {
  final Rx<MainDestination> destination;

  /// Section visited before the current one. Updated on every real switch,
  /// so drawer-less sections (Settings, mosque map) can offer a Prev button
  /// that returns the user where they came from.
  MainDestination previous;

  /// Pages already shown once. The shell builds placeholders for the rest,
  /// so heavy sections (map, sensors, book data) only initialize on first
  /// visit — then stay alive with their state.
  final RxSet<int> visited;

  MainNavController({MainDestination initial = MainDestination.adhkar})
      : destination = initial.obs,
        previous = initial,
        visited = <int>{initial.pageIndex}.obs;

  /// IndexedStack page for the current destination.
  int get pageIndex => destination.value.pageIndex;

  /// Switch to another main section. No-op when already there, so tapping
  /// the active drawer entry just closes the drawer.
  void goTo(MainDestination next) {
    visited.add(next.pageIndex);
    if (destination.value != next) {
      previous = destination.value;
      destination.value = next;
    }
  }

  /// Return to the previously visited section (Prev button on drawer-less
  /// sections). Falls back to [MainDestination.adhkar] when there is no
  /// meaningful history yet (e.g. cold start straight into Settings).
  void goBack() {
    goTo(previous == destination.value ? MainDestination.adhkar : previous);
  }

  /// Switch by page index (e.g. from persisted preferences).
  void goToPage(int page) => goTo(MainDestinationX.fromPageIndex(page));
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/core/platform/platform_channels.dart';

/// Bridge between the todo feature and the native Android home-screen
/// widget (`TodoWidgetProvider`).
///
/// Rendering + tap-to-done run fully natively against the same SQLite
/// database, so the widget works even when the app process is dead.
/// This bridge only (a) tells native to re-render after Dart-side changes
/// and (b) publishes the absolute database path once (native falls back
/// to `getDatabasePath("khatma_app.db")` when missing).
class TodoWidgetBridge {
  /// Absolute SQLite path, read by native `TodoWidgetData`.
  /// `shared_preferences` adds the `flutter.` prefix automatically.
  static const dbPathKey = 'todo_db_path';

  static Future<void> rememberDbPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(dbPathKey, path);
    } catch (e) {
      debugPrint('Error saving todo db path: $e');
    }
  }

  /// Re-render any pinned todo widgets. Fire-and-forget: safe to call
  /// even when no widget is pinned (native no-ops).
  static Future<void> refresh() async {
    try {
      await PlatformChannels.prayerNotification
          .invokeMethod('updateTodoWidget');
    } catch (e) {
      debugPrint('Error updating todo widget: $e');
    }
  }
}

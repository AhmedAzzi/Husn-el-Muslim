import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Helper class for battery optimization settings
class BatteryOptimizationHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.hisn_el_muslim/battery_optimization');

  /// Check if battery optimization is enabled for this app
  static Future<bool> isBatteryOptimizationEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isBatteryOptimizationEnabled');
      return result ?? true; // Default to true (optimized) if unknown
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return true;
    }
  }

  /// Open battery optimization settings for the user to disable it
  static Future<bool> openBatteryOptimizationSettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('Error opening battery optimization settings: $e');
      return false;
    }
  }

  /// Request to ignore battery optimization (shows system dialog)
  static Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting ignore battery optimization: $e');
      return false;
    }
  }
}

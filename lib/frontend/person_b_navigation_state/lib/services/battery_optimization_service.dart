import 'package:permission_handler/permission_handler.dart';

/// Battery Optimization Service — Ensures background service persistence.
class BatteryOptimizationService {
  /// Request to ignore battery optimizations (Android)
  Future<bool> requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Check if battery optimization is disabled for this app
  Future<bool> isBatteryOptimizationDisabled() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }
}

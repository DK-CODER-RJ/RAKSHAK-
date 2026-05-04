import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Guardian Provider — Manages the background guardian service state.
class GuardianProvider extends ChangeNotifier {
  bool _isActive = false;
  String _mode = 'passive'; // passive, alert, witness

  bool get isActive => _isActive;
  String get mode => _mode;

  /// Start guardian background service
  Future<void> startGuardian() async {
    final service = FlutterBackgroundService();
    final bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    _isActive = true;
    _mode = 'passive';
    notifyListeners();
  }

  /// Switch to alert/SOS mode
  void switchToAlertMode() {
    _mode = 'alert';
    notifyListeners();
  }

  /// Switch to witness recording mode
  void switchToWitnessMode() {
    _mode = 'witness';
    notifyListeners();
  }

  /// Stop guardian service
  void stopGuardian() {
    FlutterBackgroundService().invoke('stopService');
    _isActive = false;
    _mode = 'passive';
    notifyListeners();
  }

  /// Notify emergency contacts
  Future<void> notifyGuardians(String message) async {
    // TODO: Implement contact notification logic (SMS, Firebase Cloud Messaging, etc.)
    debugPrint('Notifying guardians: $message');
  }

  /// Monitor safe zone status
  void checkGeofences() {
    // TODO: Connect to GeofenceBloc/Repository
  }
}

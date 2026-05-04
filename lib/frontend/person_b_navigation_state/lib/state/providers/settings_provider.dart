import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Settings Provider — App settings and preferences.
class SettingsProvider extends ChangeNotifier {
  bool _voiceActivation = true;
  bool _shakeDetection = true;
  bool _nightModeAlerts = true;
  bool _backgroundService = true;
  bool _biometricLock = false;
  String _sosPin = '1234';
  List<String> _voiceKeywords = ['help', 'bachao', 'emergency'];
  bool _isLoading = true;

  final _secureStorage = const FlutterSecureStorage();

  SettingsProvider() {
    loadSettings();
  }

  bool get voiceActivation => _voiceActivation;
  bool get shakeDetection => _shakeDetection;
  bool get nightModeAlerts => _nightModeAlerts;
  bool get backgroundService => _backgroundService;
  bool get biometricLock => _biometricLock;
  bool get isLoading => _isLoading;
  String get sosPin => _sosPin;
  List<String> get voiceKeywords => _voiceKeywords;

  void toggleVoiceActivation(bool v) { _voiceActivation = v; _saveSetting('voiceActivation', v); notifyListeners(); }
  void toggleShakeDetection(bool v) { _shakeDetection = v; _saveSetting('shakeDetection', v); notifyListeners(); }
  void toggleNightModeAlerts(bool v) { _nightModeAlerts = v; _saveSetting('nightModeAlerts', v); notifyListeners(); }
  void toggleBackgroundService(bool v) { _backgroundService = v; _saveSetting('backgroundService', v); notifyListeners(); }
  void toggleBiometricLock(bool v) { _biometricLock = v; _saveSetting('biometricLock', v); notifyListeners(); }
  
  Future<void> setSosPin(String pin) async {
    _sosPin = pin;
    await _secureStorage.write(key: 'sos_pin', value: pin);
    notifyListeners();
  }

  Future<void> updateVoiceKeywords(List<String> keywords) async {
    _voiceKeywords = keywords.map((k) => k.toLowerCase().trim()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('voiceKeywords', _voiceKeywords);
    notifyListeners();
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _voiceActivation = prefs.getBool('voiceActivation') ?? true;
    _shakeDetection = prefs.getBool('shakeDetection') ?? true;
    _nightModeAlerts = prefs.getBool('nightModeAlerts') ?? true;
    _backgroundService = prefs.getBool('backgroundService') ?? true;
    _biometricLock = prefs.getBool('biometricLock') ?? false;
    _voiceKeywords = prefs.getStringList('voiceKeywords') ?? ['help', 'bachao', 'emergency'];
    
    _sosPin = await _secureStorage.read(key: 'sos_pin') ?? '1234';
    
    _isLoading = false;
    notifyListeners();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// Route Guards — Protects routes based on auth state and permissions.
class RouteGuards {
  /// Check if user is authenticated
  static bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Check if onboarding is completed
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Check if all required permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.sms,
    ];
    
    for (var permission in permissions) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }
}

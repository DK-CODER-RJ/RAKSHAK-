import 'package:permission_handler/permission_handler.dart';

/// Permission Handler Service — Centralized permission management.
class PermissionHandlerService {
  /// Request all required permissions at once
  Future<bool> requestAllPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
      Permission.phone,
      Permission.sms,
      Permission.notification,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Check if a specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Open app settings for manual permission granting
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}

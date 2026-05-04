import 'dart:math';

/// General Helper Utilities
class Helpers {
  Helpers._();

  /// Format phone number for display
  static String formatPhone(String phone) {
    if (phone.length == 10) return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    return phone;
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Generate live tracking URL
  static String generateTrackingUrl(String eventId) {
    return 'https://rakshak.app/track/$eventId';
  }

  /// Calculate distance between two coordinates in meters (Haversine)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  bool _isSosTriggered = false;

  /// Runs a check against safe zones
  /// Should be called periodically from the background isolate
  Future<void> checkSafeZones(ServiceInstance service) async {
    try {
      // 1. Check time window (12 AM to 5 AM)
      final now = DateTime.now();
      if (now.hour >= 5 && now.hour < 24) {
        // Outside of Night Mode window, reset flag and return
        _isSosTriggered = false;
        return;
      }

      if (_isSosTriggered) return; // Prevent spamming SOS

      // 2. Load safe zones
      final prefs = await SharedPreferences.getInstance();
      final String? zonesJson = prefs.getString('safe_zones');
      if (zonesJson == null || zonesJson.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(zonesJson);
      if (decoded.isEmpty) return;

      // 3. Get current location
      // Check permissions first since we are in background
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('GeofenceService: Location permission denied.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 4. Check if user is inside ANY safe zone
      bool isSafe = false;
      for (var item in decoded) {
        final double zoneLat = item['latitude'] ?? 0.0;
        final double zoneLng = item['longitude'] ?? 0.0;
        final double radius = item['radius']?.toDouble() ?? 500.0;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zoneLat,
          zoneLng,
        );

        if (distance <= radius) {
          isSafe = true;
          break; // User is safely inside at least one zone
        }
      }

      // 5. Trigger SOS if not safe
      if (!isSafe) {
        debugPrint('GeofenceService: User has left all safe zones during restricted hours! Triggering SOS.');
        _isSosTriggered = true;
        service.invoke('trigger_sos');
      }

    } catch (e) {
      debugPrint('GeofenceService error: $e');
    }
  }
}

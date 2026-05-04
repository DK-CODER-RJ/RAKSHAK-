import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Location Provider — Manages GPS tracking and location updates.
class LocationProvider extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  bool get isTracking => _isTracking;

  /// Start passive location monitoring (low power, high distance filter)
  Future<void> startPassiveTracking() async {
    _stopStream();
    _isTracking = true;
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const AndroidSettings(
        accuracy: LocationAccuracy.balanced,
        distanceFilter: 100,
        intervalDuration: Duration(minutes: 5),
      ),
    ).listen((Position position) {
      _updateLocation(position);
    });
    
    notifyListeners();
  }

  /// Start high-frequency tracking for SOS (every 3 sec)
  Future<void> startSosTracking() async {
    _stopStream();
    _isTracking = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 3),
      ),
    ).listen((Position position) {
      _updateLocation(position);
    });

    notifyListeners();
  }

  /// Stop all tracking
  void stopTracking() {
    _stopStream();
    _isTracking = false;
    notifyListeners();
  }

  void _stopStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _updateLocation(Position position) {
    _latitude = position.latitude;
    _longitude = position.longitude;
    notifyListeners();
    reverseGeocode();
  }

  /// Get current position
  Future<void> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updateLocation(position);
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }
  }

  /// Reverse geocode current coordinates to address
  Future<String?> reverseGeocode() async {
    if (_latitude == null || _longitude == null) return null;
    try {
      final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _address = '${p.name}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}';
        notifyListeners();
        return _address;
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }
}

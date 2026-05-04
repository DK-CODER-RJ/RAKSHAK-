import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeZone {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius; // in meters

  SafeZone({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius = 500,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  factory SafeZone.fromMap(Map<String, dynamic> map) {
    return SafeZone(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radius: map['radius']?.toDouble() ?? 500.0,
    );
  }
}

class SafeZoneProvider extends ChangeNotifier {
  List<SafeZone> _zones = [];
  bool _isLoading = true;

  List<SafeZone> get zones => _zones;
  bool get isLoading => _isLoading;

  SafeZoneProvider() {
    loadZones();
  }

  Future<void> loadZones() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? zonesJson = prefs.getString('safe_zones');
      
      if (zonesJson != null) {
        final List<dynamic> decoded = jsonDecode(zonesJson);
        _zones = decoded.map((item) => SafeZone.fromMap(item)).toList();
      } else {
        // Default zones
        _zones = [
          SafeZone(
            id: '1',
            name: 'Home',
            address: '123 Main Street, New Delhi',
            latitude: 28.6139,
            longitude: 77.2090,
          ),
        ];
      }
    } catch (e) {
      debugPrint('Error loading safe zones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addZone(SafeZone zone) async {
    _zones.add(zone);
    await _saveZones();
    notifyListeners();
  }

  Future<void> removeZone(String id) async {
    _zones.removeWhere((z) => z.id == id);
    await _saveZones();
    notifyListeners();
  }

  Future<void> _saveZones() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_zones.map((z) => z.toMap()).toList());
    await prefs.setString('safe_zones', encoded);
  }
}

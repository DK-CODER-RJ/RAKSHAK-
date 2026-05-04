import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak/shared/models/incident.dart';

class IncidentProvider extends ChangeNotifier {
  List<Incident> _incidents = [];
  bool _isLoading = true;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;

  IncidentProvider() {
    loadIncidents();
  }

  Future<void> loadIncidents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('incident_history');
      
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _incidents = decoded.map((item) => Incident.fromMap(item)).toList();
        // Sort by newest first
        _incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading incidents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIncident(Incident incident) async {
    _incidents.insert(0, incident);
    await _saveIncidents();
    notifyListeners();
  }

  Future<void> _saveIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_incidents.map((i) => i.toMap()).toList());
    await prefs.setString('incident_history', encoded);
  }
}

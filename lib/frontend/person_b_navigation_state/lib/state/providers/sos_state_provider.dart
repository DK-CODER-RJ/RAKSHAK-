import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:rakshak/shared/models/emergency_contact.dart';
import 'package:rakshak/integrations/media/witness_service.dart';

/// SOS State Provider — Manages emergency state lifecycle.
enum SosStatus { idle, activating, active, deactivating, cooldown }

class SosStateProvider extends ChangeNotifier {
  SosStatus _status = SosStatus.idle;
  DateTime? _activatedAt;
  String? _eventId;
  int _elapsedSeconds = 0;
  Timer? _sosTimer;
  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;
  final Telephony _telephony = Telephony.instance;

  SosStatus get status => _status;
  DateTime? get activatedAt => _activatedAt;
  String? get eventId => _eventId;
  bool get isActive => _status == SosStatus.active;
  int get elapsedSeconds => _elapsedSeconds;
  Position? get currentPosition => _currentPosition;

  /// Trigger SOS — starts the emergency protocol
  Future<void> triggerSos() async {
    if (_status == SosStatus.active || _status == SosStatus.activating) return;

    _status = SosStatus.activating;
    notifyListeners();

    _eventId = const Uuid().v4();
    _activatedAt = DateTime.now();
    _elapsedSeconds = 0;

    // Start Location Streaming first so we have location for alerts
    await _startLocationStreaming();

    // Start SOS Timer
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });

    // Start Stealth Witness Mode (Camera/Audio Recording)
    WitnessService().startWitnessMode(eventId: _eventId);

    _status = SosStatus.active;
    notifyListeners();

    // Create record in Firestore
    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(_eventId).set({
        'id': _eventId,
        'status': 'active',
        'activatedAt': _activatedAt,
        'lastLocation': _currentPosition != null 
          ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
          : null,
      });
    } catch (e) {
      debugPrint('Error creating Firestore emergency record: $e');
    }

    // AUTO-SEND SMS to all emergency contacts (no manual action needed)
    await _autoSendSmsAlerts();

    debugPrint('SOS Triggered: Event ID $_eventId');
  }

  /// Automatically send SMS to all emergency contacts — no user interaction needed
  Future<void> _autoSendSmsAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contactsJson = prefs.getString('emergency_contacts');
      if (contactsJson == null || contactsJson.isEmpty) {
        debugPrint('No emergency contacts saved.');
        return;
      }

      final List<dynamic> decoded = jsonDecode(contactsJson);
      final contacts = decoded.map((item) => EmergencyContact.fromMap(item)).toList();
      
      final String locationLink = _currentPosition != null 
        ? 'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}' 
        : 'Location unavailable';

      final String message = 'EMERGENCY! I need help URGENTLY!\n\nMy location: $locationLink\n\nThis is an automated SOS alert from RAKSHAK safety app.';

      int sentCount = 0;
      for (var contact in contacts) {
        // Clean phone number
        final String phone = contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (phone.isEmpty) continue;

        try {
          // Send SMS directly — no UI, fully automatic
          await _telephony.sendSms(
            to: phone,
            message: message,
          );
          sentCount++;
          debugPrint('SMS auto-sent to ${contact.name} ($phone)');
        } catch (e) {
          debugPrint('Failed to send SMS to ${contact.name}: $e');
        }
      }
      debugPrint('Total SMS sent: $sentCount/${contacts.length}');
    } catch (e) {
      debugPrint('Error in auto-send SMS: $e');
    }
  }

  Future<void> _startLocationStreaming() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Get immediate position first
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting initial position: $e');
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      notifyListeners();
      
      // Push to Firebase Firestore for Guardian tracking
      if (_eventId != null) {
        FirebaseFirestore.instance.collection('emergencies').doc(_eventId).set({
          'lastLocation': GeoPoint(position.latitude, position.longitude),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Cancel SOS — simple one-tap cancel
  Future<bool> cancelSos() async {
    _status = SosStatus.deactivating;
    notifyListeners();

    _sosTimer?.cancel();
    _locationSubscription?.cancel();
    
    // Stop Stealth Witness Mode
    await WitnessService().stopWitnessMode();
    
    if (_eventId != null) {
      try {
        await FirebaseFirestore.instance.collection('emergencies').doc(_eventId).update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error updating Firestore emergency record: $e');
      }
    }

    _status = SosStatus.idle;
    _activatedAt = null;
    _eventId = null;
    _elapsedSeconds = 0;
    _currentPosition = null;
    
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

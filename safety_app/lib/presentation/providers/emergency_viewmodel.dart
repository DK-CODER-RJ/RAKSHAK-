import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safety_app/core/services/location_service.dart';
import 'package:safety_app/core/services/sms_service.dart';
import 'package:safety_app/core/services/audio_recorder_service.dart';
import 'package:safety_app/core/services/places_service.dart';
import 'package:safety_app/presentation/providers/data_providers.dart';

part 'emergency_viewmodel.g.dart';

@riverpod
class EmergencyViewModel extends _$EmergencyViewModel {
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final PlacesService _placesService = PlacesService();

  @override
  FutureOr<void> build() {
    // Initialization if any
  }

  Future<void> triggerEmergency() async {
    state = const AsyncLoading();
    try {
      // 1. Start Audio Recording
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _audioRecorder.startRecording('emergency_$timestamp');

      // 2. Get Location
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getAddressFromCoordinates(
          position.latitude, position.longitude);

      // 3. Find Police Station
      final policeStation = await _placesService.getNearestPoliceStation(
          position.latitude, position.longitude);

      // 4. Construct Message
      String message = "SOS! I need help!\n"
          "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
          "Address: $address\n"
          "Nearest Police: ${policeStation['name']} (${policeStation['distance']})";

      // Fetch contacts from local/Firebase
      final contactsList =
          await ref.read(contactRepositoryProvider).getContacts();
      final List<String> emergencyNumbers = contactsList
          .map((data) => data['number'] as String? ?? '')
          .where((number) => number.isNotEmpty)
          .toList();

      // Fallback if no contacts
      final numbersToAlert =
          emergencyNumbers.isNotEmpty ? emergencyNumbers : ['100'];

      // 5. Send SMS
      await _smsService.sendEmergencySms(numbersToAlert, message);

      // 6. Save Incident to Backend (or Queue)
      await ref.read(incidentRepositoryProvider).createIncident({
        'id': timestamp,
        'type': 'EMERGENCY',
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address
        },
        'police_station': policeStation,
        'status': 'OPEN'
      });

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> stopEmergency() async {
    await _audioRecorder.stopRecording();
    state = const AsyncData(null);
  }

  Future<void> addContact(
      String name, String phoneNumber, String relation) async {
    // Assuming _contactRepo is available via ref.read(contactRepositoryProvider)
    await ref
        .read(contactRepositoryProvider)
        .addContact(name, phoneNumber, relation);
    // Assuming contactsFutureProvider exists and needs invalidation
    // ref.invalidate(contactsFutureProvider); // This provider is not defined in the current context
  }
}

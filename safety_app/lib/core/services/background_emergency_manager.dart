import 'package:safety_app/core/services/location_service.dart';
import 'package:safety_app/core/services/sms_service.dart';
import 'package:safety_app/core/services/places_service.dart';

class BackgroundEmergencyManager {
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final PlacesService _placesService = PlacesService();

  // Hardcoded contacts for background mode (since we can't easily access Riverpod state or Hive from separate isolate without initialization)
  // In a real app, pass these via shared preferences or secure storage that is reloadable.
  List<String> recipients = ['1234567890'];

  Future<void> trigger() async {
    // print("BACKGROUND EMERGENCY TRIGGERED");

    try {
      // 1. Get Location
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getAddressFromCoordinates(
          position.latitude, position.longitude);

      // 2. Find Police
      final policeStation = await _placesService.getNearestPoliceStation(
          position.latitude, position.longitude);

      // 3. Construct Message
      String message = "SOS (Voice Triggered)! I need help!\n"
          "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
          "Address: $address\n"
          "Nearest Police: ${policeStation['name']} (${policeStation['distance']})";

      // 4. Send SMS
      await _smsService.sendEmergencySms(recipients, message);

      // print("Background Emergency Sequence Complete");
    } catch (e) {
      // print("Error in background emergency: $e");
    }
  }
}

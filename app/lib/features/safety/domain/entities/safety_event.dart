import 'safety_mode.dart';

class SafetyEvent {
  const SafetyEvent({
    required this.id,
    required this.mode,
    required this.timestampIso,
    required this.latitude,
    required this.longitude,
    required this.localMediaPath,
    required this.policeStation,
    required this.policeContact,
    required this.anonymous,
  });

  final String id;
  final SafetyMode mode;
  final String timestampIso;
  final double latitude;
  final double longitude;
  final String localMediaPath;
  final String policeStation;
  final String policeContact;
  final bool anonymous;
}

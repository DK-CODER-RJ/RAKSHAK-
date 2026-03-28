import '../../domain/entities/safety_event.dart';
import '../../domain/entities/safety_mode.dart';

class SafetyEventModel extends SafetyEvent {
  const SafetyEventModel({
    required super.id,
    required super.mode,
    required super.timestampIso,
    required super.latitude,
    required super.longitude,
    required super.localMediaPath,
    required super.policeStation,
    required super.policeContact,
    required super.anonymous,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'timestampIso': timestampIso,
        'latitude': latitude,
        'longitude': longitude,
        'localMediaPath': localMediaPath,
        'policeStation': policeStation,
        'policeContact': policeContact,
        'anonymous': anonymous,
      };

  factory SafetyEventModel.fromJson(Map<String, dynamic> json) =>
      SafetyEventModel(
        id: json['id'] as String,
        mode: SafetyMode.values
            .firstWhere((element) => element.name == json['mode']),
        timestampIso: json['timestampIso'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        localMediaPath: json['localMediaPath'] as String,
        policeStation: json['policeStation'] as String,
        policeContact: json['policeContact'] as String,
        anonymous: json['anonymous'] as bool,
      );
}

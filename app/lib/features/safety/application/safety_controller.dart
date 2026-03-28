import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/voice_keywords.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/sms_service.dart';
import '../data/data_sources/local/local_storage_service.dart';
import '../data/data_sources/remote/firebase_safety_data_source.dart';
import '../data/data_sources/remote/police_lookup_service.dart';
import '../data/repositories/safety_repository_impl.dart';
import '../domain/entities/safety_event.dart';
import '../domain/entities/safety_mode.dart';
import 'safety_state.dart';

final safetyControllerProvider =
    NotifierProvider<SafetyController, SafetyState>(SafetyController.new);

class SafetyController extends Notifier<SafetyState> {
  late final LocationService _location;
  late final RecordingService _recording;
  late final SmsService _sms;
  late final PoliceLookupService _policeLookup;
  late final SafetyRepositoryImpl _repository;

  @override
  SafetyState build() {
    _location = LocationService();
    _recording = RecordingService();
    _sms = SmsService();
    _policeLookup = PoliceLookupService(Dio(), 'REPLACE_GOOGLE_API_KEY');
    _repository = SafetyRepositoryImpl(
      local: LocalStorageService('safety_events_box'),
      remote: FirebaseSafetyDataSource(FirebaseFirestore.instance),
      encryption: EncryptionService('replace-with-runtime-key'),
      connectivity: ConnectivityService(),
    );
    return const SafetyState();
  }

  Future<void> activateEmergency() async {
    state = state.copyWith(mode: SafetyMode.emergency);
    final pos = await _location.getCurrentLocation();
    final mediaPath = await _recording.startEmergencyRecording();
    final police = await _policeLookup.nearestPolice(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    final mapLink =
        'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    final message = 'EMERGENCY! Need help. '
        'Location: ${pos.latitude}, ${pos.longitude}. '
        'Map: $mapLink. '
        'Nearest Police: ${police.stationName} (${police.contact})';

    await _sms.sendEmergencySms(
      contacts: state.emergencyContacts,
      message: message,
    );

    await _repository.enqueueEvent(
      SafetyEvent(
        id: const Uuid().v4(),
        mode: SafetyMode.emergency,
        timestampIso: DateTime.now().toIso8601String(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        localMediaPath: mediaPath,
        policeStation: police.stationName,
        policeContact: police.contact,
        anonymous: false,
      ),
    );

    state = state.copyWith(
      lastEventSummary:
          'Emergency triggered at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
    );
  }

  Future<void> activateWitness() async {
    state = state.copyWith(mode: SafetyMode.witness);
    final pos = await _location.getCurrentLocation();
    final mediaPath = await _recording.captureWitnessClip();
    final police = await _policeLookup.nearestPolice(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    await _repository.enqueueEvent(
      SafetyEvent(
        id: const Uuid().v4(),
        mode: SafetyMode.witness,
        timestampIso: DateTime.now().toIso8601String(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        localMediaPath: mediaPath,
        policeStation: police.stationName,
        policeContact: police.contact,
        anonymous: state.anonymousWitness,
      ),
    );

    state = state.copyWith(
      lastEventSummary:
          'Witness report captured at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
    );
  }

  Future<void> syncNow() async {
    await _repository.syncPendingEvents();
  }

  void setEmergencyContacts(List<String> contacts) {
    state = state.copyWith(emergencyContacts: contacts);
  }

  void setAnonymousWitness(bool value) {
    state = state.copyWith(anonymousWitness: value);
  }

  void reset() {
    state = state.copyWith(mode: SafetyMode.idle);
  }

  Future<void> simulateVoiceKeyword(String keyword) async {
    final value = keyword.trim().toLowerCase();
    if (VoiceKeywords.emergency.contains(value)) {
      await activateEmergency();
    } else if (VoiceKeywords.witness.contains(value)) {
      await activateWitness();
    }
  }
}

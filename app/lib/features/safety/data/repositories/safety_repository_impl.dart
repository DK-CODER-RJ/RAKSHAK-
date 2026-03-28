import 'package:uuid/uuid.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/encryption_service.dart';
import '../../domain/entities/safety_event.dart';
import '../../domain/repositories/safety_repository.dart';
import '../data_sources/local/local_storage_service.dart';
import '../data_sources/remote/firebase_safety_data_source.dart';
import '../models/safety_event_model.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl({
    required this.local,
    required this.remote,
    required this.encryption,
    required this.connectivity,
  });

  final LocalStorageService local;
  final FirebaseSafetyDataSource remote;
  final EncryptionService encryption;
  final ConnectivityService connectivity;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> enqueueEvent(SafetyEvent event) async {
    final model = SafetyEventModel(
      id: event.id.isEmpty ? _uuid.v4() : event.id,
      mode: event.mode,
      timestampIso: event.timestampIso,
      latitude: event.latitude,
      longitude: event.longitude,
      localMediaPath: event.localMediaPath,
      policeStation: event.policeStation,
      policeContact: event.policeContact,
      anonymous: event.anonymous,
    );

    final encrypted = encryption.encryptJson(model.toJson());
    await local.put(model.id, encrypted);

    if (await connectivity.isOnline()) {
      await remote.uploadEvent(model);
      await remote.forwardToAuthority(model);
      await local.delete(model.id);
    }
  }

  @override
  Future<List<SafetyEvent>> pendingEvents() async {
    final records = await local.getAll();
    return records.values
        .map(
            (value) => SafetyEventModel.fromJson(encryption.decryptJson(value)))
        .toList(growable: false);
  }

  @override
  Future<void> syncPendingEvents() async {
    if (!await connectivity.isOnline()) return;
    final records = await local.getAll();
    for (final entry in records.entries) {
      final model =
          SafetyEventModel.fromJson(encryption.decryptJson(entry.value));
      await remote.uploadEvent(model);
      await remote.forwardToAuthority(model);
      await local.delete(entry.key);
    }
  }
}

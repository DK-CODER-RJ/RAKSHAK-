import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_app/data/repositories/contact_repository.dart';
import 'package:safety_app/data/repositories/incident_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

final contactsFutureProvider = FutureProvider((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.getContacts();
});

final incidentsFutureProvider = FutureProvider((ref) {
  final repo = ref.watch(incidentRepositoryProvider);
  return repo.getIncidents();
});

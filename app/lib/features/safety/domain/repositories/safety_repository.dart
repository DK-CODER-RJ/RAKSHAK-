import '../entities/safety_event.dart';

abstract class SafetyRepository {
  Future<void> enqueueEvent(SafetyEvent event);
  Future<List<SafetyEvent>> pendingEvents();
  Future<void> syncPendingEvents();
}

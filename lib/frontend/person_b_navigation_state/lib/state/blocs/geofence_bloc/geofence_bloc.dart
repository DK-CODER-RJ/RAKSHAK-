import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Geofence States
abstract class GeofenceState extends Equatable {
  const GeofenceState();
  @override
  List<Object?> get props => [];
}

class GeofenceIdle extends GeofenceState {}
class GeofenceMonitoring extends GeofenceState {
  final List<String> activeZones;
  const GeofenceMonitoring({this.activeZones = const []});
  @override
  List<Object?> get props => [activeZones];
}
class GeofenceAlert extends GeofenceState {
  final String zoneId;
  final String message;
  const GeofenceAlert(this.zoneId, this.message);
  @override
  List<Object?> get props => [zoneId, message];
}

/// Geofence Events
abstract class GeofenceEvent extends Equatable {
  const GeofenceEvent();
  @override
  List<Object?> get props => [];
}

class AddZone extends GeofenceEvent {
  final String zoneId;
  const AddZone(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}
class RemoveZone extends GeofenceEvent {
  final String zoneId;
  const RemoveZone(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}
class EnterZone extends GeofenceEvent {
  final String zoneId;
  const EnterZone(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}
class ExitZone extends GeofenceEvent {
  final String zoneId;
  const ExitZone(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}
class ToggleNightMode extends GeofenceEvent {}

/// Geofence Bloc — Business logic for safe zones monitoring.
class GeofenceBloc extends Bloc<GeofenceEvent, GeofenceState> {
  GeofenceBloc() : super(GeofenceIdle()) {
    on<AddZone>((event, emit) {
      // Logic to add a geofence zone
    });

    on<RemoveZone>((event, emit) {
      // Logic to remove a geofence zone
    });

    on<EnterZone>((event, emit) {
      emit(GeofenceAlert(event.zoneId, 'Entered safe zone'));
    });

    on<ExitZone>((event, emit) {
      emit(GeofenceAlert(event.zoneId, 'Exited safe zone - Alerting guardians'));
    });
    
    on<ToggleNightMode>((event, emit) {
      // Logic to toggle night mode monitoring
    });
  }
}

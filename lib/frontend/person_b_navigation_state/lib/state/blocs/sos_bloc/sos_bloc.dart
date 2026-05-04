import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// SOS States
abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}
class SosActivating extends SosState {}
class SosActive extends SosState {
  final String eventId;
  const SosActive(this.eventId);
  @override
  List<Object?> get props => [eventId];
}
class SosDeactivating extends SosState {}
class SosCooldown extends SosState {}
class SosError extends SosState {
  final String message;
  const SosError(this.message);
  @override
  List<Object?> get props => [message];
}

/// SOS Events
abstract class SosEvent extends Equatable {
  const SosEvent();
  @override
  List<Object?> get props => [];
}

class TriggerSos extends SosEvent {}
class CancelSos extends SosEvent {}
class UpdateLocation extends SosEvent {
  final double lat;
  final double lon;
  const UpdateLocation(this.lat, this.lon);
  @override
  List<Object?> get props => [lat, lon];
}
class SendAlert extends SosEvent {}

/// SOS Bloc — Business logic for emergency SOS protocol.
class SosBloc extends Bloc<SosEvent, SosState> {
  SosBloc() : super(SosInitial()) {
    on<TriggerSos>((event, emit) async {
      emit(SosActivating());
      // Logic to trigger SOS (API call, etc.)
      await Future.delayed(const Duration(seconds: 1));
      emit(const SosActive('temp_event_id'));
    });

    on<CancelSos>((event, emit) async {
      emit(SosDeactivating());
      // Logic to cancel SOS
      await Future.delayed(const Duration(milliseconds: 500));
      emit(SosInitial());
    });

    on<UpdateLocation>((event, emit) {
      if (state is SosActive) {
        // Handle location update during active SOS
      }
    });

    on<SendAlert>((event, emit) {
      // Logic to send alerts to contacts
    });
  }
}

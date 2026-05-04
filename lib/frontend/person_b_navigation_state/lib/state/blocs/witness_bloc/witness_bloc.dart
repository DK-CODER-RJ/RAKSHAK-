import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Witness States
abstract class WitnessState extends Equatable {
  const WitnessState();
  @override
  List<Object?> get props => [];
}

class WitnessIdle extends WitnessState {}
class WitnessRecording extends WitnessState {
  final bool isBlackScreen;
  const WitnessRecording({this.isBlackScreen = false});
  @override
  List<Object?> get props => [isBlackScreen];
}
class WitnessUploading extends WitnessState {
  final double progress;
  const WitnessUploading(this.progress);
  @override
  List<Object?> get props => [progress];
}
class WitnessComplete extends WitnessState {
  final String evidenceUrl;
  const WitnessComplete(this.evidenceUrl);
  @override
  List<Object?> get props => [evidenceUrl];
}
class WitnessError extends WitnessState {
  final String message;
  const WitnessError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Witness Events
abstract class WitnessEvent extends Equatable {
  const WitnessEvent();
  @override
  List<Object?> get props => [];
}

class StartRecording extends WitnessEvent {}
class StopRecording extends WitnessEvent {}
class UploadEvidence extends WitnessEvent {
  final String filePath;
  const UploadEvidence(this.filePath);
  @override
  List<Object?> get props => [filePath];
}
class ToggleBlackScreen extends WitnessEvent {}

/// Witness Bloc — Business logic for witness mode recording.
class WitnessBloc extends Bloc<WitnessEvent, WitnessState> {
  WitnessBloc() : super(WitnessIdle()) {
    on<StartRecording>((event, emit) {
      emit(const WitnessRecording());
    });

    on<StopRecording>((event, emit) {
      emit(WitnessIdle());
    });

    on<ToggleBlackScreen>((event, emit) {
      if (state is WitnessRecording) {
        final current = state as WitnessRecording;
        emit(WitnessRecording(isBlackScreen: !current.isBlackScreen));
      }
    });

    on<UploadEvidence>((event, emit) async {
      emit(const WitnessUploading(0.0));
      // Logic to upload evidence
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        emit(WitnessUploading(i * 0.1));
      }
      emit(const WitnessComplete('https://rakshak.app/evidence/temp_id'));
    });
  }
}

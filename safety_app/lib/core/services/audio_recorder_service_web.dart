import 'package:record/record.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();

  Future<void> startRecording(String fileName) async {
    // Web: Record to memory/blob, path is ignored or handled internally
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(const RecordConfig(),
          path: ''); // Empty path for web usually triggers stream/blob
    }
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
}

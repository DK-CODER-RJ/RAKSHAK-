import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();

  Future<void> startRecording(String fileName) async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/$fileName.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
    }
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
}

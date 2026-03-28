import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<void> init() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
    }
  }

  Future<void> startVideoRecording(String filePath) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (_controller!.value.isRecordingVideo) {
      return;
    }

    // Note: startVideoRecording in newer camera plugins might handle file paths differently
    // or return an XFile after stopping.
    await _controller!.startVideoRecording();
  }

  Future<XFile?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return null;
    }
    return await _controller!.stopVideoRecording();
  }

  CameraController? get controller => _controller;

  void dispose() {
    _controller?.dispose();
  }
}

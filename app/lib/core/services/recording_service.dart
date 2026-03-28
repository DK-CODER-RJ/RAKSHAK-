class RecordingService {
  Future<String> startEmergencyRecording() async {
    // Return local path from camera/audio plugin.
    return 'local://evidence/emergency_media.mp4';
  }

  Future<String> captureWitnessClip() async {
    // Capture 15-30 second clip in production.
    return 'local://evidence/witness_clip.mp4';
  }
}

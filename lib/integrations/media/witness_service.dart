import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:rakshak/integrations/media/upload_service.dart';

/// WitnessService — Handles stealth camera/audio recording and local chunking.
class WitnessService {
  static final WitnessService _instance = WitnessService._internal();
  factory WitnessService() => _instance;
  WitnessService._internal();

  CameraController? _cameraController;
  Timer? _chunkTimer;
  bool _isRecording = false;
  final Duration _chunkDuration = const Duration(seconds: 30);
  final List<String> _recordedChunks = [];

  bool get isRecording => _isRecording;
  List<String> get recordedChunks => _recordedChunks;

  String? _currentEventId;

  /// Starts the stealth recording process
  Future<void> startWitnessMode({String? eventId}) async {
    _currentEventId = eventId;
    if (_isRecording) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('WitnessMode: No cameras available');
        return;
      }

      // Prefer front camera for witness mode
      CameraDescription targetCamera = cameras.first;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          targetCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      _isRecording = true;
      
      await _startRecordingChunk();

      // Set up timer to chunk the recordings
      _chunkTimer = Timer.periodic(_chunkDuration, (timer) async {
        await _startRecordingChunk();
      });

      debugPrint('WitnessMode: Stealth recording activated.');
    } catch (e) {
      debugPrint('WitnessMode Error starting: $e');
      _isRecording = false;
    }
  }

  Future<void> _startRecordingChunk() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      if (_cameraController!.value.isRecordingVideo) {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        await _saveChunk(videoFile);
      }

      await _cameraController!.startVideoRecording();
      debugPrint('WitnessMode: Started new video chunk.');
    } catch (e) {
      debugPrint('WitnessMode Error during chunk recording: $e');
    }
  }

  Future<void> _saveChunk(XFile videoFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String witnessDir = '${appDir.path}/witness_evidence';
      final dir = Directory(witnessDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String newPath = '$witnessDir/evidence_$timestamp.mp4';
      
      await videoFile.saveTo(newPath);
      _recordedChunks.add(newPath);
      debugPrint('WitnessMode: Saved chunk to $newPath');

      // Prep for upload logic would go here
      UploadService().uploadEvidence(newPath, eventId: _currentEventId);
    } catch (e) {
      debugPrint('WitnessMode Error saving chunk: $e');
    }
  }

  /// Stops recording and cleans up resources
  Future<void> stopWitnessMode() async {
    if (!_isRecording) return;
    
    _chunkTimer?.cancel();
    _chunkTimer = null;

    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        await _saveChunk(videoFile);
      } catch (e) {
        debugPrint('WitnessMode Error stopping video: $e');
      }
    }

    await _cameraController?.dispose();
    _cameraController = null;
    _isRecording = false;
    debugPrint('WitnessMode: Stealth recording deactivated.');
  }
}

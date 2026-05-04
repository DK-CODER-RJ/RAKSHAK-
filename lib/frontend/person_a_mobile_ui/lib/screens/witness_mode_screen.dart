import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/incident_provider.dart';
import 'package:rakshak/shared/models/incident.dart';
import 'package:uuid/uuid.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';

/// Witness Mode Screen — Records video evidence with location.
class WitnessModeScreen extends StatefulWidget {
  const WitnessModeScreen({super.key});

  @override
  State<WitnessModeScreen> createState() => _WitnessModeScreenState();
}

class _WitnessModeScreenState extends State<WitnessModeScreen> {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  String? _errorMessage;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras found on this device');
        return;
      }

      // Use back camera
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // Medium for smaller file size
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
        debugPrint('📹 Camera initialized successfully');
      }
    } catch (e) {
      debugPrint('📹 Error initializing camera: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Camera error: $e');
      }
    }
  }

  Future<String> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Location service disabled';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return 'Location permission denied';
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [place.street, place.locality, place.administrativeArea]
            .where((p) => p != null && p.isNotEmpty)
            .toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
      }
      
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('Location error: $e');
      return 'Location unavailable';
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready. Please wait...');
      await _initializeCamera();
      return;
    }

    if (_cameraController!.value.isRecordingVideo) {
      debugPrint('📹 Already recording');
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _seconds++);
        }
      });

      debugPrint('📹 Video recording started');
    } catch (e) {
      debugPrint('📹 Error starting recording: $e');
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      debugPrint('📹 Not recording, nothing to stop');
      return;
    }

    _timer?.cancel();

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      setState(() => _isRecording = false);
      
      debugPrint('📹 Video saved to: ${videoFile.path}');
      debugPrint('📹 Video file size: ${await File(videoFile.path).length()} bytes');

      // Show saving indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Saving recording with location...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Get location
      final locationStr = await _getCurrentLocation();
      debugPrint('📍 Location: $locationStr');

      // Copy video to app's permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/witness_recordings');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      
      final fileName = 'witness_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final permanentPath = '${videoDir.path}/$fileName';
      await File(videoFile.path).copy(permanentPath);
      debugPrint('📹 Video copied to: $permanentPath');

      // Save to incident history
      if (mounted) {
        final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);
        final newIncident = Incident(
          id: 'WIT-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          type: 'WITNESS',
          timestamp: DateTime.now(),
          location: locationStr,
          mediaPath: permanentPath,
          status: 'Saved',
        );
        await incidentProvider.addIncident(newIncident);
        debugPrint('📹 Incident saved to history');

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Recording saved! Location: $locationStr'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('📹 Error stopping recording: $e');
      setState(() => _isRecording = false);
      _showError('Error saving recording: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isRecording ? Colors.black : const Color(0xFF1976D2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isRecording) {
              _stopRecording().then((_) {
                if (context.mounted) Navigator.pop(context);
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isRecording ? 'Recording...' : 'Witness Mode',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _isRecording ? _buildRecordingView() : _buildIdleView(),
      ),
    );
  }

  Widget _buildRecordingView() {
    return Column(
      children: [
        // Live camera preview
        Expanded(
          child: _isCameraInitialized && _cameraController != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CameraPreview(_cameraController!),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),

        // Timer + recording indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'REC  ${_formatTime(_seconds)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stop button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'STOP RECORDING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIdleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            ),

          // Eye icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isCameraInitialized ? Icons.videocam_outlined : Icons.hourglass_top,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Witness Mode',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _isCameraInitialized 
              ? 'Record evidence of crimes or incidents.\nVideo + Location will be saved securely.'
              : 'Initializing camera...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          ),

          const SizedBox(height: 32),

          // Features card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                _FeatureRow(icon: Icons.videocam_outlined, label: 'Video Recording with Audio'),
                SizedBox(height: 16),
                _FeatureRow(icon: Icons.location_on_outlined, label: 'GPS Location & Address'),
                SizedBox(height: 16),
                _FeatureRow(icon: Icons.history, label: 'Saved to Incident History'),
                SizedBox(height: 16),
                _FeatureRow(icon: Icons.play_circle_outline, label: 'Playback in History'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Safety card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Safety First', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                ...['Only record from a safe distance', 'Do not confront or engage', 'Your safety is the priority'].map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text('• ', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                        Flexible(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Start Recording button
          GestureDetector(
            onTap: _isCameraInitialized ? _startRecording : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isCameraInitialized ? Colors.white : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCameraInitialized ? Icons.videocam_outlined : Icons.hourglass_top,
                    color: const Color(0xFF1976D2),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCameraInitialized ? 'START RECORDING' : 'CAMERA LOADING...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 16),
        Flexible(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ],
    );
  }
}

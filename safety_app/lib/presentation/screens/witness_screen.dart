import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:safety_app/core/constants/app_colors.dart';
import 'package:safety_app/core/services/camera_service.dart';
import 'package:safety_app/presentation/screens/witness_report_screen.dart';

class WitnessScreen extends StatefulWidget {
  const WitnessScreen({super.key});

  @override
  State<WitnessScreen> createState() => _WitnessScreenState();
}

class _WitnessScreenState extends State<WitnessScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInit = false;
  bool _showCamera = false;
  bool _isRecording = false;
  bool _isProcessingVideo = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.init();
    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  Future<void> _startRecordingFlow() async {
    if (!_isInit) return;
    setState(() {
      _showCamera = true;
      _recordSeconds = 0;
    });
    // Add small delay to let camera preview render
    await Future.delayed(const Duration(milliseconds: 300));
    await _cameraService.startVideoRecording('');

    if (mounted) {
      setState(() => _isRecording = true);
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordSeconds++);
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() => _isProcessingVideo = true);

      final file = await _cameraService.stopVideoRecording();

      if (mounted) {
        setState(() {
          _isProcessingVideo = false;
          _isRecording = false;
          _showCamera = false;
        });
      }

      if (file != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WitnessReportScreen(videoPath: file.path),
          ),
        );
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return 'REC ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  Widget _buildWitnessInfoView() {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        title: const Text("Witness Mode"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Eye Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Titles
                      const Text(
                        "Witness Mode",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Record evidence of crimes or incidents you\nwitness. Help others safely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Features Card 1
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeatureRow(
                                icon: Icons.videocam_outlined,
                                text: "Discreet Video Recording"),
                            SizedBox(height: 20),
                            _FeatureRow(
                                icon: Icons.location_on_outlined,
                                text: "Location & Timestamp"),
                            SizedBox(height: 20),
                            _FeatureRow(
                                icon: Icons.check_circle_outline,
                                text: "Anonymous Reporting"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Features Card 2 (Safety Warning)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: AppColors.warning),
                                SizedBox(width: 10),
                                Text(
                                  "Safety First",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _BulletText("Only record from a safe distance"),
                            SizedBox(height: 6),
                            _BulletText("Do not confront or engage"),
                            SizedBox(height: 6),
                            _BulletText("Your safety is the priority"),
                            SizedBox(height: 6),
                            _BulletText("Evidence will be securely stored"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20), // Replaces the Spacer
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Start Recording Button
              InkWell(
                onTap: _startRecordingFlow,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_outlined,
                          color: AppColors.primaryGreen, size: 28),
                      SizedBox(width: 12),
                      Text(
                        "START RECORDING",
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_cameraService.controller != null)
            Positioned.fill(
              child: CameraPreview(_cameraService.controller!),
            ),

          // Overlay UI
          if (!_isProcessingVideo)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: _stopRecording,
                    child: const Icon(Icons.stop,
                        color: AppColors.primaryGreen, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDuration(_recordSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  )
                ],
              ),
            ),

          if (_isProcessingVideo)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: 20),
                    Text(
                      "Saving Evidence...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_showCamera) {
      return _buildCameraView();
    }

    return _buildWitnessInfoView();
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0, right: 8.0, left: 4.0),
          child: CircleAvatar(radius: 2.5, backgroundColor: Colors.white),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

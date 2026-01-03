import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../core/auth/face_detection_service.dart';
import '/core/auth/auth_repository.dart';
import '/theme/app_theme.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _controller;
  final _faceService = FaceDetectionService();
  final _authRepo = AuthRepository();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _controller = CameraController(front, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  void _captureAndEnroll() async {
    if (_controller == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Capture the image (Visual Feedback for user)
      final image = await _controller!.takePicture();
      // We process bytes just to simulate work, even if not sending
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // --- DEMO MODE MODIFICATION ---
      // SKIPPED: final success = await _authRepo.setupFacial("identity_rail_init", base64Image);
      // Instead, we simulate a network delay and proceed purely on local capture success. 
      // Remember guys, this is only till we get the ML scripts working. 
      
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate enrollment time

      if (mounted) {
        Navigator.pushNamed(context, '/security-setup');
      }
      
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(
        title: const Text("Identity Enrollment"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Brand colored scanner ring
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BlockPayTheme.electricGreen.withOpacity(0.3), 
                        width: 2
                      ),
                    ),
                  ),
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: BlockPayTheme.electricGreen, width: 2),
                    ),
                    child: ClipOval(
                      child: _controller?.value.isInitialized ?? false
                          ? CameraPreview(_controller!)
                          : Container(color: BlockPayTheme.surfaceGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  "Align your face within the frame",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  "This creates your unique biometric identity.",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    onPressed: _isProcessing ? null : _captureAndEnroll,
                    backgroundColor: BlockPayTheme.electricGreen,
                    foregroundColor: Colors.black,
                    shape: const CircleBorder(),
                    child: _isProcessing 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Icon(Icons.face_unlock_sharp, size: 36),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
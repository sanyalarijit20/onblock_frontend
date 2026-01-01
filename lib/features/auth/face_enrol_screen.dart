import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '/core/auth/auth_repository.dart';

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
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    setState(() {});
  }

  void _captureFace() async {
    if (_controller == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // In Step 2, we send the image to the ML Microservice via backend
      // We'll use a placeholder string for "facialData" geometry for now
      final success = await _authRepo.setupFacial("geometry_hash_placeholder", base64Image);

      if (success && mounted) {
        Navigator.pushNamed(context, '/security-setup');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Face Identity Enrollment")),
      body: Column(
        children: [
          Expanded(
            child: _controller?.value.isInitialized ?? false
                ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: CameraPreview(_controller!))
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text("Position your face within the frame", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _captureFace,
                  child: _isProcessing ? const CircularProgressIndicator() : const Icon(Icons.camera_front),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
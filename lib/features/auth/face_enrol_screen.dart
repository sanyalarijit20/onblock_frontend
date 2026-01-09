import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/auth/face_detection_service.dart';
import '../../core/auth/auth_repository.dart';
import '/theme/app_theme.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _controller;
  // Note: Ensure the file is named face_detection_service.dart
  final _faceService = FaceDetectionService(); 
  final _authRepo = AuthRepository();
  bool _isProcessing = false;
  String _feedbackText = "Align face within the ring";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first
    );
    
    _controller = CameraController(
      front, 
      ResolutionPreset.medium, 
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    
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
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _feedbackText = "Encrypting Biometric Data...";
    });

    try {
      // 1. Capture Image
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2. Call AuthRepository
      // 'facialData' is a placeholder string here. 
      // In a full implementation, you might pass actual ML Kit landmarks json here.
      final bool success = await _authRepo.setupFacial(
        "identity_rail_init", 
        base64Image
      );

      if (success) {
        if (mounted) {
          setState(() => _feedbackText = "Identity Verified!");
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric Enrollment Complete"),
              backgroundColor: BlockPayTheme.electricGreen,
            )
          );
          
          // Navigate to next step (Security Setup)
          Navigator.pushReplacementNamed(context, '/security-setup');
        }
      } else {
        throw Exception("Server rejected biometric data.");
      }

    } catch (e) {
      if (mounted) {
        setState(() => _feedbackText = "Enrollment Failed. Try Again.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(
        title: const Text("Identity Enrollment"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Ring
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isProcessing 
                            ? BlockPayTheme.electricGreen 
                            : BlockPayTheme.electricGreen.withOpacity(0.3),
                        width: _isProcessing ? 6 : 2
                      ),
                      boxShadow: _isProcessing ? [
                         BoxShadow(
                           color: BlockPayTheme.electricGreen.withOpacity(0.4),
                           blurRadius: 30,
                           spreadRadius: 5
                         )
                      ] : [],
                    ),
                  ),
                  // Camera Feed
                  Container(
                    width: size.width * 0.72,
                    height: size.width * 0.72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: ClipOval(
                      child: _controller?.value.isInitialized ?? false
                          ? CameraPreview(_controller!)
                          : const Center(child: CircularProgressIndicator(color: BlockPayTheme.electricGreen)),
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
                  _feedbackText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _isProcessing ? BlockPayTheme.electricGreen : Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Face Identity Setup Complete.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    onPressed: _isProcessing ? null : _captureAndEnroll,
                    backgroundColor: BlockPayTheme.electricGreen,
                    foregroundColor: Colors.black,
                    elevation: 10,
                    shape: const CircleBorder(),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                          )
                        : const Icon(Icons.camera_alt, size: 36),
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
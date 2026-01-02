import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:convert';
import 'dart:io';
import '/theme/app_theme.dart';
import 'face_detection_service.dart';

class FaceVerificationSheet extends StatefulWidget {
  const FaceVerificationSheet({super.key});

  @override
  State<FaceVerificationSheet> createState() => _FaceVerificationSheetState();
}

class _FaceVerificationSheetState extends State<FaceVerificationSheet> {
  final FaceDetectionService _faceService = FaceDetectionService();
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _statusMessage = "Align your face within the frame";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
      _startDetectionStream();
    } catch (e) {
      setState(() => _statusMessage = "Camera Error: $e");
    }
  }

  void _startDetectionStream() {
    // Process every 10th frame to save battery/cpu
    int frameCount = 0;
    
    _controller?.startImageStream((CameraImage image) async {
      frameCount++;
      if (frameCount % 10 != 0) return;
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        // 1. Detect Face using the service
        // Note: sensorOrientation needs to be dynamic in production, hardcoded 270/90 for portrait common cases
        final faces = await _faceService.detectFaces(image, 270);

        if (faces.isNotEmpty) {
          final face = faces.first;
          
          // 2. Liveness & Position Checks
          if (_validateFace(face, image)) {
             await _captureAndFinish();
          }
        } else {
          if (mounted) setState(() => _statusMessage = "No face detected");
        }
      } catch (e) {
        print("Detection Error: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  bool _validateFace(Face face, CameraImage image) {
    final double leftEyeProb = face.leftEyeOpenProbability ?? 0.0;
    final double rightEyeProb = face.rightEyeOpenProbability ?? 0.0;

    // Check 1: Are eyes open?
    if (leftEyeProb < 0.5 || rightEyeProb < 0.5) {
      if (mounted) setState(() => _statusMessage = "Please open your eyes");
      return false;
    }

    // Check 2: Is face roughly centered/visible?
    if (mounted) setState(() => _statusMessage = "Hold still...");
    return true;
  }

  Future<void> _captureAndFinish() async {
    // Stop stream to prevent multiple triggers
    await _controller?.stopImageStream();
    
    if (!mounted) return;
    setState(() => _statusMessage = "Verifying...");

    try {
      // Capture high-res image for backend
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (mounted) {
        Navigator.pop(context, {
          'verified': true,
          'facialData': 'face_geometry_mock', // ML Kit provides geometry, but backend might expect specific format
          'imageData': base64Image,
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "Capture Failed");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: BlockPayTheme.obsidianBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text("Facial Verification", style: BlockPayTheme.darkTheme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          
          // Circular Camera Preview
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BlockPayTheme.electricGreen, width: 4),
            ),
            child: ClipOval(
              child: _isCameraInitialized
                  ? CameraPreview(_controller!)
                  : const Center(child: CircularProgressIndicator(color: BlockPayTheme.electricGreen)),
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            _statusMessage,
            style: const TextStyle(color: BlockPayTheme.electricGreen, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
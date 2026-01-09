import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
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
  String _statusMessage = "Blink to confirm payment";
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceService.resetLivenessState();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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
    int frameCount = 0;
    
    _controller?.startImageStream((CameraImage image) async {
      frameCount++;
      if (frameCount % 5 != 0) return; // Process every 5th frame
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        final faces = await _faceService.detectFaces(image, 270); // Assume portrait

        if (faces.isNotEmpty) {
          final face = faces.first;
          _validateLiveness(face);
        } else {
          // Reset state if face lost
          if (mounted) setState(() => _statusMessage = "Align face within frame");
        }
      } catch (e) {
        print("Detection Error: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  void _validateLiveness(Face face) {
    if(!mounted) return;

    // Check if liveness is confirmed (blink detected)
    if (_faceService.checkLiveness(face)) {
      _confirmVerification();
    } else {
      final blinkCount = _faceService.getBlinkCount();
      setState(() => _statusMessage = "Blink detected: $blinkCount/1");
    }
  }

  Future<void> _confirmVerification() async {
    await _controller?.stopImageStream();
    
    if (mounted) {
      setState(() => _statusMessage = "Verified!");
      // Return success to the caller (Payment Screen or Login)
      Navigator.pop(context, {'verified': true});
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
      height: MediaQuery.of(context).size.height * 0.75,
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
          Text("Confirm Transaction", style: BlockPayTheme.darkTheme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          
          // Circular Camera Preview
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _statusMessage == "Verified!" ? BlockPayTheme.electricGreen : Colors.white24, 
                width: 4
              ),
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
            style: const TextStyle(color: BlockPayTheme.electricGreen, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Blink to authorize payment",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
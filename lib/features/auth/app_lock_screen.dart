import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../core/auth/biometric_service.dart';
import '../../core/auth/secure_storage.dart';
import '/core/auth/auth_repository.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _bioService = BiometricService();
  final _authRepo = AuthRepository();
  final _storage = SecureStorage();
  
  bool _useFaceAuth = false;
  CameraController? _cameraController;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger native biometrics (Fingerprint/PIN) on entry
    _triggerNativeAuth();
  }

  Future<void> _triggerNativeAuth() async {
    final success = await _bioService.authenticateForEntry();
    if (success) {
      _navigateToDashboard();
    }
  }

  Future<void> _initFaceAuth() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    setState(() => _useFaceAuth = true);
  }

  void _verifyFace() async {
    if (_cameraController == null || _isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Calls app-level Face ML verification on the backend
      final verified = await _authRepo.verifyFacialIdentity("current_session_token", base64Image);

      if (verified) {
        _navigateToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face Identity not recognized"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              "BlockPay Locked",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text("Verify identity to access your wallet", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 60),
            
            if (!_useFaceAuth) ...[
              ElevatedButton.icon(
                onPressed: _triggerNativeAuth,
                icon: const Icon(Icons.fingerprint),
                label: const Text("USE FINGERPRINT / PIN"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(250, 55)),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _initFaceAuth,
                icon: const Icon(Icons.face),
                label: const Text("USE FACE IDENTITY"),
              ),
            ] else ...[
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: ClipOval(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _isVerifying 
                ? const CircularProgressIndicator()
                : FloatingActionButton.extended(
                    onPressed: _verifyFace,
                    label: const Text("VERIFY FACE"),
                    icon: const Icon(Icons.camera),
                  ),
              TextButton(
                onPressed: () => setState(() => _useFaceAuth = false),
                child: const Text("BACK TO FINGERPRINT"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
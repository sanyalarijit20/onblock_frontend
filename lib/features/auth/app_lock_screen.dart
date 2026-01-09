import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../core/auth/biometric_service.dart';
import '../../core/auth/auth_repository.dart';
import '/theme/app_theme.dart';

enum AuthMode { biometric, face, passkey }

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _bioService = BiometricService();
  final _authRepo = AuthRepository();
  final _passkeyController = TextEditingController();
  
  AuthMode _currentMode = AuthMode.biometric;
  CameraController? _cameraController;
  bool _isVerifying = false;
  String _statusMessage = "Select authentication method";

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric (fingerprint) on load
    _triggerNativeAuth();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  // --- 1. Fingerprint Logic ---
  Future<void> _triggerNativeAuth() async {
    if (!mounted) return;
    setState(() {
      _currentMode = AuthMode.biometric;
      _statusMessage = "Touch sensor to unlock";
    });

    final success = await _bioService.authenticateForEntry();
    if (success) {
      _unlockApp();
    } else {
      if (mounted) setState(() => _statusMessage = "Authentication failed");
    }
  }

  // --- 2. Face Auth Logic (Connected to AuthRepo) ---
  Future<void> _initFaceAuth() async {
    setState(() {
      _currentMode = AuthMode.face;
      _statusMessage = "Initializing Camera...";
    });

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first
    );

    _cameraController = CameraController(
      front, 
      ResolutionPreset.medium, 
      enableAudio: false
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() {
        _statusMessage = "Look at the camera to unlock";
      });
      // Automatically snap and verify after a brief pause to let camera adjust
      Future.delayed(const Duration(milliseconds: 500), _scanAndVerifyFace);
    }
  }

  Future<void> _scanAndVerifyFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() => _statusMessage = "Verifying Identity...");

      // Call AuthRepository to verify face
      // "session_unlock" is a context string for the backend to know why we are verifying
      final bool isValid = await _authRepo.verifyFacialIdentity(
        "session_unlock", 
        base64Image
      );

      if (isValid) {
        _unlockApp();
      } else {
        if (mounted) setState(() => _statusMessage = "Face not recognized");
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "Verification Error");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // --- 3. Passkey Logic ---
  Future<void> _verifyPasskey() async {
    final input = _passkeyController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isVerifying = true);
    
    // Using verifyPasskey from AuthRepository
    final success = await _authRepo.verifyPasskey(input);
    
    if (success) {
      _unlockApp();
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = "Incorrect Passkey";
          _isVerifying = false;
        });
        _passkeyController.clear();
      }
    }
  }

  void _unlockApp() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              _getIconForMode(_currentMode), 
              size: 60, 
              color: BlockPayTheme.electricGreen
            ),
            const SizedBox(height: 16),
            Text(
              "Security Required", 
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            
            // Dynamic Body based on Auth Mode
            Expanded(
              flex: 3, 
              child: Center(child: _buildAuthBody())
            ),
            
            // Mode Switcher Bottom Bar
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modeIconButton(Icons.fingerprint, AuthMode.biometric),
                  const SizedBox(width: 20),
                  _modeIconButton(Icons.face, AuthMode.face),
                  const SizedBox(width: 20),
                  _modeIconButton(Icons.password, AuthMode.passkey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMode(AuthMode mode) {
    switch (mode) {
      case AuthMode.biometric: return Icons.fingerprint;
      case AuthMode.face: return Icons.face;
      case AuthMode.passkey: return Icons.lock;
    }
  }

  Widget _buildAuthBody() {
    if (_currentMode == AuthMode.face) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: BlockPayTheme.electricGreen.withOpacity(0.5), width: 2),
        ),
        child: ClipOval(
          child: _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : const Center(child: Icon(Icons.camera_alt, color: Colors.white24, size: 40)),
        ),
      );
    } else if (_currentMode == AuthMode.passkey) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passkeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter Passkey",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.key, color: BlockPayTheme.electricGreen),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyPasskey,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlockPayTheme.electricGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isVerifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text("Unlock"),
            )
          ],
        ),
      );
    } else {
      // Biometric Placeholder
      return GestureDetector(
        onTap: _triggerNativeAuth,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BlockPayTheme.electricGreen.withOpacity(0.1),
          ),
          child: const Icon(Icons.fingerprint, size: 60, color: BlockPayTheme.electricGreen),
        ),
      );
    }
  }

  Widget _modeIconButton(IconData icon, AuthMode mode) {
    bool isActive = _currentMode == mode;
    return IconButton(
      icon: Icon(icon, size: 28),
      color: isActive ? BlockPayTheme.electricGreen : BlockPayTheme.subtleGrey,
      onPressed: () {
        // Dispose camera if leaving face mode
        if (_currentMode == AuthMode.face && mode != AuthMode.face) {
          _cameraController?.dispose();
          _cameraController = null;
        }
        
        if (mode == AuthMode.face) {
          _initFaceAuth();
        } else if (mode == AuthMode.biometric) {
          _triggerNativeAuth();
        } else {
          setState(() {
             _currentMode = mode;
             _statusMessage = "Enter your passkey";
          });
        }
      },
    );
  }
}
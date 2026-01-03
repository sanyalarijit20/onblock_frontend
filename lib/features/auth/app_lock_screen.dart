import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/auth/biometric_service.dart';
import '/core/auth/auth_repository.dart';
import '/theme/app_theme.dart';
import '../../utils/validators.dart';

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
  final _formKey = GlobalKey<FormState>();
  AuthMode _currentMode = AuthMode.biometric;
  CameraController? _cameraController;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Start with Fingerprint prompt automatically
    _triggerNativeAuth();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  // --- Logic Hub ---

  Future<void> _triggerNativeAuth() async {
    setState(() => _currentMode = AuthMode.biometric);
    final success = await _bioService.authenticateForEntry();
    if (success) _navigateToDashboard();
  }

  Future<void> _initFaceAuth() async {
    setState(() => _isVerifying = true);
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    setState(() {
      _currentMode = AuthMode.face;
      _isVerifying = false;
    });
  }

  void _verifyFace() async {
    if (_cameraController == null || _isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      // We capture the image just to mimic the interaction
      final image = await _cameraController!.takePicture(); // the value of image isn't used, which is expected for the demo
      // final bytes = await image.readAsBytes(); // Unused in demo mode logic
      
      // --- DEMO MODE MODIFICATION ---
      // SKIP: final verified = await _authRepo.verifyFacialIdentity("session_unlock", base64Image);
      
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate processing, SIRF dikhana hai
      _navigateToDashboard();
      // ------------------------------

    } catch (e) {
      _showError("Authentication error. Try again.");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _verifyPasskey() async {
    if (!_formKey.currentState!.validate() || _isVerifying) return;
    
    setState(() => _isVerifying = true);

    final success = await _authRepo.verifyPasskey(_passkeyController.text);
    if (success) {
      _navigateToDashboard();
    } else {
      _showError("Invalid Passkey");
      setState(() => _isVerifying = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  // --- UI Components ---

  Widget _buildAuthBody() {
    switch (_currentMode) {
      case AuthMode.face:
        return _buildFaceUI();
      case AuthMode.passkey:
        return _buildPasskeyUI();
      default:
        return _buildBiometricUI();
    }
  }

  Widget _buildBiometricUI() {
    return Column(
      children: [
        const Icon(Icons.fingerprint, size: 100, color: BlockPayTheme.electricGreen),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _triggerNativeAuth,
          child: const Text("TAP SENSOR TO UNLOCK"),
        ),
      ],
    );
  }

  Widget _buildFaceUI() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const CircularProgressIndicator(color: BlockPayTheme.electricGreen);
    }
    return Column(
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: BlockPayTheme.electricGreen, width: 2),
          ),
          child: ClipOval(child: CameraPreview(_cameraController!)),
        ),
        const SizedBox(height: 32),
        _isVerifying
          ? const CircularProgressIndicator(color: BlockPayTheme.electricGreen)
          : ElevatedButton(
              onPressed: _verifyFace,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 56)),
              child: const Text("VERIFY IDENTITY"),
            ),
      ],
    );
  }

  Widget _buildPasskeyUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey, 
        child: Column(
          children: [
            TextFormField(
              controller: _passkeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "••••••",
                labelText: "Enter App Passkey",
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validatePasskey, 
            ),
            const SizedBox(height: 24),
            _isVerifying
              ? const CircularProgressIndicator(color: BlockPayTheme.electricGreen)
              : ElevatedButton(
                  onPressed: _verifyPasskey,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: const Text("UNLOCK WALLET"),
                ),
          ],
        ),
      ),
    );
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
            const Icon(Icons.shield_outlined, size: 60, color: BlockPayTheme.electricGreen),
            const SizedBox(height: 16),
            Text("Security Required", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 40),
            
            Expanded(flex: 3, child: Center(child: _buildAuthBody())),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modeIconButton(Icons.fingerprint, AuthMode.biometric),
                  const SizedBox(width: 30),
                  _modeIconButton(Icons.face, AuthMode.face),
                  const SizedBox(width: 30),
                  _modeIconButton(Icons.password, AuthMode.passkey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeIconButton(IconData icon, AuthMode mode) {
    bool isActive = _currentMode == mode;
    return IconButton(
      icon: Icon(icon, size: 32),
      color: isActive ? BlockPayTheme.electricGreen : BlockPayTheme.subtleGrey,
      onPressed: () {
        if (mode == AuthMode.face) {
          _initFaceAuth();
        } else {
          setState(() => _currentMode = mode);
        }
      },
    );
  }
}
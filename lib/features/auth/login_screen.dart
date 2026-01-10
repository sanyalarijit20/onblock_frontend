import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/core/auth/biometric_service.dart';
import '../../core/auth/face_verification_screen.dart';
import '/features/profile/dashboard_screen.dart';
import '/core/auth/auth_repository.dart';
import '/core/auth/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final BiometricService _biometricService = BiometricService();
  final AuthRepository _authRepo = AuthRepository();
  final SecureStorage _storage = SecureStorage();
  bool _isLoading = false;

  /// Handles Login Success. 
  /// [isHardwareUnlock] allows bypassing the JWT check for client-side demo purposes.
  Future<void> _handleLoginSuccess({bool isHardwareUnlock = false}) async {
    final hasWallet = await _storage.hasWallet();
    final token = await _storage.getJwt();

    if (!hasWallet) {
      _showError("Identity missing on this device. Please Register.");
      return;
    }

    // If it's a passkey login, we MUST have a token.
    // If it's hardware, we allow entry to show the "Identity-Only" dashboard state.
    if (!isHardwareUnlock && token == null) {
      _showError("Session expired. Please use your Passkey.");
      return;
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _loginWithBiometrics() async {
    final hasIdentity = await _storage.hasWallet();
    if (!hasIdentity) {
      _showError("No account detected. Please register first.");
      return;
    }

    // Client-side hardware verification
    final authenticated = await _biometricService.authenticateForEntry();
    if (authenticated) {
      // hardware unlock = true: enters dashboard immediately
      await _handleLoginSuccess(isHardwareUnlock: true);
    }
  }

  Future<void> _loginWithFaceID() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FaceVerificationSheet(),
    );
    
    if (result != null && result['verified'] == true) {
      // hardware unlock = true
      await _handleLoginSuccess(isHardwareUnlock: true);
    }
  }

  Future<void> _loginWithPasskey() async {
    final passkey = await _showPasskeyDialog();
    if (passkey != null && passkey.isNotEmpty) {
      if (mounted) setState(() => _isLoading = true);
      try {
        // Backend verification to restore full session (JWT)
        final success = await _authRepo.verifyPasskey(passkey);
        if (success) {
          await _handleLoginSuccess(isHardwareUnlock: false);
        } else {
          _showError("Incorrect Passkey. Access Denied.");
        }
      } catch (e) {
        _showError("Connection failed. Try again.");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Auth Hub", style: BlockPayTheme.darkTheme.textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text("Unlock your identity with device security", style: TextStyle(color: BlockPayTheme.subtleGrey)),
            const SizedBox(height: 48),
            
            _AuthOptionTile(
              icon: Icons.fingerprint,
              title: "Biometric Unlock",
              subtitle: "Hardware-level security",
              onTap: _loginWithBiometrics,
            ),
            const SizedBox(height: 16),
            _AuthOptionTile(
              icon: Icons.face_retouching_natural,
              title: "Facial Recognition",
              subtitle: "Client-side identity check",
              onTap: _loginWithFaceID,
            ),
            const SizedBox(height: 16),
            _AuthOptionTile(
              icon: Icons.keyboard_alt_outlined,
              title: "App Passkey",
              subtitle: "Full session sync with backend",
              onTap: _loginWithPasskey,
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator(color: BlockPayTheme.electricGreen)),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _showPasskeyDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: BlockPayTheme.surfaceGrey,
          title: const Text("Verify Passkey", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white, letterSpacing: 4),
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(hintText: "••••••"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("VERIFY"),
            ),
          ],
        );
      },
    );
  }
}

class _AuthOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AuthOptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BlockPayTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BlockPayTheme.electricGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: BlockPayTheme.electricGreen),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
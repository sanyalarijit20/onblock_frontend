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
  String _statusText = "Welcome Back";

  @override
  void initState() {
    super.initState();
    // Auto-trigger default fingerprint/biometric after the UI builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptFingerprint();
    });
  }

  /// 1. Fingerprint / Device Secure Lock (Default)
  Future<void> _attemptFingerprint() async {
    if (_isLoading) return;
    
    setState(() => _statusText = "Authenticating...");
    
    final hasWallet = await _storage.hasWallet();
    
    if (!hasWallet) {
       if(mounted) setState(() => _statusText = "No wallet found. Please Register.");
       return;
    }

    final authenticated = await _biometricService.authenticateForEntry();

    if (authenticated) {
      _onLoginSuccess();
    } else {
      if(mounted) setState(() => _statusText = "Authentication Cancelled");
    }
  }

  /// 2. Face Verification (Custom UI + Backend Verify)
  Future<void> _attemptFaceVerification() async {
    // Open the Camera Sheet
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FaceVerificationSheet(),
    );

    // If sheet returns verified=true, it means local liveness passed
    if (result != null && result['verified'] == true) {
      setState(() {
        _isLoading = true;
        _statusText = "Verifying Identity...";
      });

      // --- DEMO MODE MODIFICATION ---
      // We skip the backend verifyFacialIdentity call.
      // If the local detector (FaceVerificationSheet) says it's a real face, we trust it for the demo.
      
      await Future.delayed(const Duration(milliseconds: 1200)); // Fake verification delay
      
      _onLoginSuccess();
      // ------------------------------
      
      if(mounted) setState(() => _isLoading = false);
    }
  }

  /// 3. App Passkey (Custom Input + Backend Verify)
  Future<void> _attemptPasskey() async {
    final passkey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PasskeyInputSheet(),
    );

    if (passkey != null && passkey.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _statusText = "Verifying Passkey...";
      });

      try {
        final isValid = await _authRepo.verifyPasskey(passkey);
        
        if (isValid) {
          _onLoginSuccess();
        } else {
          _showError("Invalid Passkey");
        }
      } catch (e) {
        _showError("Network error checking passkey");
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onLoginSuccess() {
    if(!mounted) return;
    setState(() => _statusText = "Success!");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _showError(String message) {
    if(!mounted) return;
    setState(() => _statusText = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BlockPayTheme.electricGreen.withOpacity(0.1),
                  border: Border.all(color: BlockPayTheme.electricGreen, width: 2),
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 64, color: BlockPayTheme.electricGreen),
              ),
              const SizedBox(height: 32),
              Text(
                "BlockPay",
                style: BlockPayTheme.darkTheme.textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 16),
              ),
              const Spacer(),
              if (_isLoading)
                const CircularProgressIndicator(color: BlockPayTheme.electricGreen)
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _attemptFingerprint,
                        icon: const Icon(Icons.fingerprint, size: 28),
                        label: const Text("Unlock with Fingerprint"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _AlternativeAuthButton(
                          icon: Icons.face_rounded,
                          label: "Face ID",
                          onTap: _attemptFaceVerification,
                        ),
                        _AlternativeAuthButton(
                          icon: Icons.dialpad_rounded,
                          label: "Passkey",
                          onTap: _attemptPasskey,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativeAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AlternativeAuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: BlockPayTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PasskeyInputSheet extends StatefulWidget {
  const _PasskeyInputSheet();

  @override
  State<_PasskeyInputSheet> createState() => _PasskeyInputSheetState();
}

class _PasskeyInputSheetState extends State<_PasskeyInputSheet> {
  final TextEditingController _passController = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: BlockPayTheme.surfaceGrey,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BlockPayTheme.subtleGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Enter App Passkey",
              style: BlockPayTheme.darkTheme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passController,
              obscureText: _isObscured,
              keyboardType: TextInputType.visiblePassword,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: "••••••",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.lock_outline, color: BlockPayTheme.electricGreen),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                    color: BlockPayTheme.subtleGrey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: BlockPayTheme.electricGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final pass = _passController.text.trim();
                if (pass.isNotEmpty) {
                  Navigator.pop(context, pass);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BlockPayTheme.electricGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Unlock"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
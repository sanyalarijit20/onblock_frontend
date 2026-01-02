import 'package:flutter/material.dart';
import '../../core/auth/biometric_service.dart';
import '/core/auth/auth_repository.dart';
import '/theme/app_theme.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _bioService = BiometricService();
  final _authRepo = AuthRepository();
  bool _fingerprintDone = false;
  bool _isProcessing = false;

  void _setupFingerprint() async {
    setState(() => _isProcessing = true);
    final authenticated = await _bioService.authenticate(
      reason: 'Enroll your hardware fingerprint for rapid payments',
      biometricOnly: true,
    );

    if (authenticated) {
      final success = await _authRepo.setupBiometric("device_auth_v1", "HP_EliteBook_G11");
      if (success) {
        setState(() => _fingerprintDone = true);
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(title: const Text("Hardware Security")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Step 3: Device Binding", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              "Bind your physical fingerprint to your BlockPay wallet for gasless transactions.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            
            // Themed Card for Fingerprint
            Card(
              child: InkWell(
                onTap: _fingerprintDone || _isProcessing ? null : _setupFingerprint,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BlockPayTheme.electricGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _fingerprintDone ? Icons.verified : Icons.fingerprint,
                          size: 40,
                          color: BlockPayTheme.electricGreen,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fingerprintDone ? "Fingerprint Bound" : "Link Fingerprint",
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _fingerprintDone ? "Hardware identity active" : "Tap to enroll sensor",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (_isProcessing) 
                        const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            ElevatedButton(
              onPressed: _fingerprintDone ? () => Navigator.pushNamed(context, '/wallet-setup') : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text("FINALIZE SETUP"),
            )
          ],
        ),
      ),
    );
  }
}
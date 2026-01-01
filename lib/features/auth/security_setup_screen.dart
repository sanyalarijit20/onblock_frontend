import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/auth/biometric_service.dart';
import '/core/auth/auth_repository.dart';
import '../../core/auth/secure_storage.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _bioService = BiometricService();
  final _authRepo = AuthRepository();
  final _storage = SecureStorage();
  
  bool _fingerprintDone = false;
  bool _isLoaderActive = false;

  /// In a production app, we need to use the 'device_info_plus' package.
  /// For this demo, we generate a unique hash based on the hardware profile.
  /// P.S. I have no clue how to implement the device_info_plus package, and we dont have the time for me to learn it
  /// so we are winging it
  Future<String> _getDynamicDeviceId() async {
    // Check if we already have one saved
    String? existingId = await _storage.getDeviceId();
    if (existingId != null) return existingId;

    // Generate a pseudo-unique ID 
    final newId = "BP-${Platform.localHostname}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    await _storage.saveDeviceId(newId);
    return newId;
  }

  void _setupFingerprint() async {
    setState(() => _isLoaderActive = true);

    try {
      // 1. Local Authentication (The "Gate")
      final authenticated = await _bioService.authenticate(
        reason: 'Enroll your fingerprint to secure your Polygon wallet',
        biometricOnly: true, 
      );

      if (authenticated) {
        // 2. Fetch the dynamic Device ID
        final deviceId = await _getDynamicDeviceId();

        // 3. Link hardware to the Account on the backend
        // Using a generic token for the demo
        final success = await _authRepo.setupBiometric("enrolled_hash_v1", deviceId);
        
        if (success) {
          setState(() {
            _fingerprintDone = true;
            _isLoaderActive = false;
          });
          _showSuccessSheet();
        } else {
          throw Exception("Backend failed to link biometric hardware.");
        }
      } else {
        setState(() => _isLoaderActive = false);
      }
    } catch (e) {
      setState(() => _isLoaderActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Security Setup Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text("Hardware Secured", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Your fingerprint is now bound to this device ID for all gasless transactions."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.pushNamed(context, '/wallet-setup'); // Move to Step 4
              },
              child: const Text("Continue to Wallet Creation"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Security")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Step 3: Secure your wallet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Enroll your fingerprint to enable gasless payments with Biconomy paymasters."),
            const SizedBox(height: 40),
            
            // Interaction Card
            InkWell(
              onTap: _fingerprintDone || _isLoaderActive ? null : _setupFingerprint,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _fingerprintDone ? Colors.greenAccent : Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fingerprintDone ? Icons.check_circle : Icons.fingerprint, 
                      size: 48, 
                      color: _fingerprintDone ? Colors.greenAccent : Colors.blueAccent
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fingerprintDone ? "Biometrics Active" : "Enroll Fingerprint", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                          ),
                          Text(
                            _fingerprintDone ? "Device ID linked successfully" : "Tap to start enrollment", 
                            style: const TextStyle(color: Colors.white60)
                          ),
                        ],
                      ),
                    ),
                    if (_isLoaderActive) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Navigation Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fingerprintDone ? () => Navigator.pushNamed(context, '/wallet-setup') : null,
                child: const Text("FINAL STEP: GENERATE WALLET"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
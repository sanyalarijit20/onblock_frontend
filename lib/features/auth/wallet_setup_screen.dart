import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/auth/secure_storage.dart';
import 'dart:math';

class WalletSetupScreen extends StatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  State<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends State<WalletSetupScreen> {
  final _storage = SecureStorage();
  bool _isGenerating = true;

  @override
  void initState() {
    super.initState();
    _generateWallet();
  }

  Future<void> _generateWallet() async {
    // Simulating Local Private Key Generation
    // In a real scenario, this would involve the Biconomy SDK or ethers.dart
    await Future.delayed(const Duration(seconds: 3));
    
    final mockPrivateKey = "0x${List.generate(64, (i) => Random().nextInt(16).toRadixString(16)).join()}";
    final mockWalletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";

    // Saving to the Ryzen-backed encrypted storage
    await _storage.savePrivateKey(mockPrivateKey);
    await _storage.saveWalletAddress(mockWalletAddress);
    
    // Grabbing the device ID we generated in Step 3
    final deviceId = await _storage.getDeviceId() ?? "HP_Elite_845_G11";
    await _storage.saveDeviceId(deviceId);

    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isGenerating 
                ? Lottie.asset(
                    'assets/animations/wallet_gen.json', 
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ) 
                : const Icon(Icons.check_circle_outline, size: 100, color: Colors.greenAccent),
              const SizedBox(height: 30),
              Text(
                _isGenerating ? "Securing Your Identity..." : "Identity Rail Ready",
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isGenerating 
                  ? "We are sealing your private keys in your device's secure enclave." 
                  : "Your Aadhaar, face geometry, and wallet are now unified.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 60),
              if (!_isGenerating)
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  child: const Text("LAUNCH DASHBOARD"),
                )
            ],
          ),
        ),
      ),
    );
  }
}
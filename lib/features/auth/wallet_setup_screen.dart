import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/auth/secure_storage.dart';
import '/theme/app_theme.dart';
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
    await Future.delayed(const Duration(seconds: 4));
    
    final mockPrivateKey = "0x${List.generate(64, (i) => Random().nextInt(16).toRadixString(16)).join()}";
    final mockWalletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";

    await _storage.savePrivateKey(mockPrivateKey);
    await _storage.saveWalletAddress(mockWalletAddress);
    await _storage.saveDeviceId("HP_EliteBook_G11");

    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isGenerating 
                ? Lottie.asset(
                    'assets/Wallet.json',
                    width: 250,
                    height: 250,
                  )
                : const Icon(Icons.check_circle, size: 100, color: BlockPayTheme.electricGreen),
              const SizedBox(height: 32),
              Text(
                _isGenerating ? "Securing Your Vault" : "Identity Linked!",
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                _isGenerating 
                  ? "Generating your private keys in your Ryzen 7 secure enclave..." 
                  : "Your wallet is ready. Your face and fingerprint are now your keys.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 60),
              if (!_isGenerating)
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: const Text("ENTER BLOCKPAY"),
                )
            ],
          ),
        ),
      ),
    );
  }
}
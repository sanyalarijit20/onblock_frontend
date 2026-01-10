import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  // Removed unused _storage and _hasWallet variable
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BlockPayTheme.electricGreen.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(),
                  const Hero(
                    tag: 'app_logo',
                    child: Icon(Icons.security_rounded, size: 80, color: BlockPayTheme.electricGreen),
                  ),
                  const SizedBox(height: 24),
                  Text("ONBLOCK", style: BlockPayTheme.darkTheme.textTheme.displayLarge),
                  const SizedBox(height: 12),
                  const Text(
                    "Secure, Invisible, Decentralized",
                    style: TextStyle(color: BlockPayTheme.subtleGrey, letterSpacing: 1.5, fontSize: 12),
                  ),
                  const Spacer(),
                  
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RegistrationScreen())
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 64),
                      backgroundColor: BlockPayTheme.electricGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("CREATE NEW ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen())
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 64),
                      side: const BorderSide(color: Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      "ALREADY A USER? LOG IN",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
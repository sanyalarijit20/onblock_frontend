import 'package:flutter/material.dart';
import 'core/auth/secure_storage.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/auth/face_enrol_screen.dart';
import 'features/auth/security_setup_screen.dart';
import 'features/auth/wallet_setup_screen.dart';
import 'features/profile/dashboard_screen.dart'; 
import '/theme/app_theme.dart';

void main() async {
  // Ensures the Flutter engine is fully initialized before we access platform-specific 
  // features like Secure Storage or the Camera 
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = SecureStorage();
  
  // Checking local device state to determine entry point
  final bool hasWallet = await storage.hasWallet();
  final bool hasToken = await storage.hasToken();

  // Smart Routing Logic for "Invisible Rail" Onboarding:
  // 1. If wallet exists (Private key saved) -> Standard App Entry (Lock Screen)
  // 2. If token exists but no wallet -> User left during setup, resume at Face Enrollment
  // 3. Otherwise -> First time user (Registration)
  String initialRoute = '/register';
  
  if (hasWallet) {
    initialRoute = '/lock';
  } else if (hasToken) {
    initialRoute = '/face-enrollment';
  }

  runApp(BlockPayApp(initialRoute: initialRoute));
}

class BlockPayApp extends StatelessWidget {
  final String initialRoute;
  const BlockPayApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlockPay',
      debugShowCheckedModeBanner: false,
      
      // Applying custom BlockPay Obsidian & Electric Green theme
      themeMode: ThemeMode.dark,
      darkTheme: BlockPayTheme.darkTheme,
      
      initialRoute: initialRoute,
      routes: {
        '/lock': (context) => const AppLockScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/face-enrollment': (context) => const FaceEnrollmentScreen(),
        '/security-setup': (context) => const SecuritySetupScreen(),
        '/wallet-setup': (context) => const WalletSetupScreen(),
        '/dashboard': (context) => const DashboardScreen(), 
      },
    );
  }
}
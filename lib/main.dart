import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth/secure_storage.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/auth/face_enrol_screen.dart'; 
import 'features/auth/security_setup_screen.dart';
import 'features/auth/wallet_setup_screen.dart';
import 'features/profile/dashboard_screen.dart'; 
import 'features/payment/scan_qr_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensuring the Flutter engine is ready for Fedora/Android platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for consistent Biometric scanning UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storage = SecureStorage();
  
  // Checking local device state to determine entry point for the "Invisible Rail"
  final bool hasWallet = await storage.hasWallet(); // Smart Account address exists
  final bool hasToken = await storage.hasToken();   // JWT exists

  String initialRoute = '/register';
  
  if (hasWallet && hasToken) {
    initialRoute = '/lock';
  } else if (hasToken && !hasWallet) {
    // If they have a session but setup was interrupted, send back to biometrics
    initialRoute = '/face-enrollment';
  }

  runApp(OnBlockApp(initialRoute: initialRoute));
}

class OnBlockApp extends StatelessWidget {
  final String initialRoute;
  const OnBlockApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnBlock',
      debugShowCheckedModeBanner: false,
      
      // Applying the custom Obsidian & Electric Green theme for the MVP
      themeMode: ThemeMode.dark,
      theme: BlockPayTheme.darkTheme, // Fallback if system is light
      darkTheme: BlockPayTheme.darkTheme,
      
      initialRoute: initialRoute,
      
      // Standardized routes for the CSE project demo
      routes: {
        '/lock': (context) => const AppLockScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/face-enrollment': (context) => const FaceEnrollmentScreen(),
        '/security-setup': (context) => const SecuritySetupScreen(),
        '/wallet-setup': (context) => const WalletSetupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scan': (context) => const ScannerScreen(),
      },
    );
  }
}
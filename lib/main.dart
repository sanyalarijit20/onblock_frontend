import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth/secure_storage.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/auth/face_enrol_screen.dart'; 
import 'features/auth/security_setup_screen.dart';
import 'features/auth/wallet_setup_screen.dart';
import 'features/profile/dashboard_screen.dart'; 
import 'features/payment/scan_qr_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for consistent Biometric scanning UI on the HP EliteBook
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storage = SecureStorage();
  
  // Checking local device state
  final bool hasWallet = await storage.hasWallet(); 
  final bool hasToken = await storage.hasToken();   

  // Navigation Logic based on the "Invisible Rail" state:
  // Default to the Launch Pad (App Lock Screen) as requested
  String initialRoute = '/lock';
  
  // If the user has a session but didn't finish the hardware setup, 
  // we resume the sequence automatically.
  if (hasToken && !hasWallet) {
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
      themeMode: ThemeMode.dark,
      theme: BlockPayTheme.darkTheme,
      darkTheme: BlockPayTheme.darkTheme,
      
      initialRoute: initialRoute,
      
      // Standardized routes reflecting the recent screen changes
      routes: {
        // The Launch Pad (Landing Page)
        '/lock': (context) => const AppLockScreen(),
        
        // The Auth Hub (Login)
        '/login': (context) => const LoginScreen(),
        
        // The Registration Flow
        '/register': (context) => const RegistrationScreen(),
        '/face-enrollment': (context) => const FaceEnrollmentScreen(),
        '/security-setup': (context) => const SecuritySetupScreen(),
        '/wallet-setup': (context) => const WalletSetupScreen(),
        
        // Core App Experience
        '/dashboard': (context) => const DashboardScreen(),
        '/scan': (context) => const ScannerScreen(),
      },
    );
  }
}
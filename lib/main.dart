import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth/secure_storage.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/auth/face_enrol_screen.dart';
import 'features/auth/security_setup_screen.dart';
import 'features/auth/wallet_setup_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = SecureStorage();
  final bool hasWallet = await storage.hasWallet();
  final bool hasToken = await storage.hasToken();

  runApp(BlockPayApp(initialRoute: hasWallet ? '/lock' : '/register'));
}

class BlockPayApp extends StatelessWidget {
  final String initialRoute;
  const BlockPayApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlockPay',
      themeMode: ThemeMode.dark,
      darkTheme: BlockPayTheme.darkTheme,
      initialRoute: initialRoute,
      routes: {
        '/lock': (context) => const AppLockScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/face-enrollment': (context) => const FaceEnrollmentScreen(),
        '/security-setup': (context) => const SecuritySetupScreen(),
        '/wallet-setup': (context) => const WalletSetupScreen(),
        '/dashboard': (context) => const DashboardScreen(), // final dashboard, which we make on day 2, abhi mai sone ja raha
      },
    );
  }
}
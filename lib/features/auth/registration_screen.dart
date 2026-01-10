import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '/core/auth/auth_repository.dart';
import '../../utils/validators.dart';
import '/theme/app_theme.dart';
import 'login_screen.dart'; // Import login screen for navigation

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  
  // Controllers for the fields expected by the auth_controller
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final user = await _authRepo.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passController.text,
      );
      
      if (user != null && mounted) {
        // Successful registration leads to the next step of the invisible rail
        Navigator.pushNamed(context, '/face-enrollment');
      }
    } catch (e) {
      debugPrint("Registration Error: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 780, // Adjusted height for additional link
            borderRadius: 24,
            blur: 20,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
            ),
            borderGradient: LinearGradient(
              colors: [BlockPayTheme.electricGreen.withOpacity(0.5), Colors.transparent],
            ),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: BlockPayTheme.electricGreen, size: 48),
                    const SizedBox(height: 16),
                    Text("Join BlockPay", style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "First Name"),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "Last Name"),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Mobile", prefixIcon: Icon(Icons.phone_android)),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Passkey", prefixIcon: Icon(Icons.lock_outline)),
                      validator: Validators.validatePasskey,
                    ),
                    const Spacer(),
                    _isLoading 
                      ? const CircularProgressIndicator(color: BlockPayTheme.electricGreen)
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: const Text("NEXT: FACE IDENTITY"),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              ),
                              child: const Text(
                                "ALREADY HAVE AN ACCOUNT? LOG IN",
                                style: TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 12, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
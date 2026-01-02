import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '/core/auth/auth_repository.dart';
import '../../utils/validators.dart';
import '/theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _aadhaarController = TextEditingController();

  bool _isLoading = false;

  void _handleRegister() async {
    // This stops the code here if validation fails, 
    // showing the red errors without trying to proceed.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passController.text,
        aadhaarNumber: _aadhaarController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushNamed(context, '/face-enrollment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BlockPayTheme.electricGreen.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassmorphicContainer(
                width: double.infinity,
                // Height increased to 820 to accommodate all validation error strings
                height: 820, 
                borderRadius: 24,
                blur: 20,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    BlockPayTheme.electricGreen.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined, 
                          color: BlockPayTheme.electricGreen, 
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text("Join BlockPay", style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          "Step 1: Identity Onboarding",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name", 
                            prefixIcon: Icon(Icons.person_outline)
                          ),
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address", 
                            prefixIcon: Icon(Icons.email_outlined)
                          ),
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Mobile Number", 
                            prefixIcon: Icon(Icons.phone_android)
                          ),
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Aadhaar Number", 
                            prefixIcon: Icon(Icons.fingerprint)
                          ),
                          validator: Validators.validateAadhaar,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "App Passkey", 
                            prefixIcon: Icon(Icons.lock_outline)
                          ),
                          validator: Validators.validatePasskey,
                        ),
                        
                        const Spacer(),
                        _isLoading 
                          ? const CircularProgressIndicator(color: BlockPayTheme.electricGreen)
                          : ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: const Text("NEXT: FACE IDENTITY"),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
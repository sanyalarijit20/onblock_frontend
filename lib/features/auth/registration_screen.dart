import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '/core/auth/auth_repository.dart';

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
    // Ensuring we use the form's validation logic
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
        // Move to the next step in the Onboarding logic
        Navigator.pushNamed(context, '/face-enrollment');
      }
    } catch (e) {
      // Showing the error message returned by our ApiClient wrapper
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Obsidian Black base
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_mesh.png'), 
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 680,
              borderRadius: 30,
              blur: 25,
              alignment: Alignment.center,
              border: 1.5,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
              ),
              borderGradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent]
              ),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    children: [
                      const Text(
                        "Join BlockPay", 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Step 1: Identity Verification", 
                        style: TextStyle(color: Colors.white60, fontSize: 14)
                      ),
                      const SizedBox(height: 30),
                      
                      // Now using the Validators class for strict alignment with Backend
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => (v == null || !v.contains('@')) ? "Invalid email" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_android)),
                        // Ensure it matches Indian 10-digit standard
                        validator: (v) => (v != null && v.length == 10) ? null : "Enter 10-digit number",
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _aadhaarController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Aadhaar Number", prefixIcon: Icon(Icons.fingerprint)),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v != null && v.length == 12) ? null : "12 digits required",
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Set App Password", prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                        validator: (v) => (v != null && v.length >= 8) ? null : "Minimum 8 characters",
                      ),
                      
                      const Spacer(),
                      _isLoading 
                        ? const CircularProgressIndicator(color: Colors.blueAccent)
                        : ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
      ),
    );
  }
}
import 'package:community/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:community/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _sendResetLink() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final success =
        await _authService.forgotPassword(email: _emailController.text);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send reset link. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                decoration: AppTheme.glassmorphismDecoration,
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.lock_reset,
                              size: 100, color: Colors.white)
                          .animate()
                          .fade(duration: 1.seconds)
                          .slideY(begin: -0.5, curve: Curves.easeOut),
                      const SizedBox(height: 20),
                      Text(
                        "Forgot Your Password?",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        "Enter your email and we'll send a reset link",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      _buildTextField(
                          controller: _emailController,
                          hint: "Email",
                          icon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          }),
                      const SizedBox(height: 30),
                      _buildResetButton(),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back to Sign In",
                            style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.orange),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: AppTheme.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      style: Theme.of(context).elevatedButtonTheme.style,
      onPressed: _sendResetLink,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("Send Reset Link",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
    ).animate().fade(delay: 500.ms).slideX(begin: 0.5, curve: Curves.easeOut);
  }
}

import 'package:community/screens/main_screen.dart';
import 'package:community/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:community/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'attendee';
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _register() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration successful!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _register,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                      const Icon(Icons.celebration,
                              size: 100, color: Colors.white)
                          .animate()
                          .fade(duration: 1.seconds)
                          .slideY(begin: -0.5, curve: Curves.easeOut),
                      const SizedBox(height: 20),
                      Text(
                        "Join CommUnity",
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                      ),
                      Text(
                        "Create your account",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryColor,
                            ),
                      ),
                      const SizedBox(height: 50),
                      _buildTextField(
                          controller: _usernameController,
                          hint: "Username",
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          }),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: _passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          }),
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: _confirmPasswordController,
                          hint: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          }),
                      const SizedBox(height: 20),
                      _buildRoleDropdown(),
                      const SizedBox(height: 20),
                      _buildRegisterButton(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?",
                              style: TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Sign In",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
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
      bool isPassword = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: InputDecoration(
        hintText: "Select Role",
        hintStyle: const TextStyle(color: Colors.orange),
        prefixIcon: const Icon(Icons.group, color: Colors.orange),
        filled: true,
        fillColor: AppTheme.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: AppTheme.glassWhite,
      style: const TextStyle(color: Colors.black),
      items: const [
        DropdownMenuItem(value: 'attendee', child: Text('Attendee')),
        DropdownMenuItem(value: 'organizer', child: Text('Organizer')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      style: Theme.of(context).elevatedButtonTheme.style,
      onPressed: _register,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("Sign Up",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
    ).animate().fade(delay: 500.ms).slideX(begin: 0.5, curve: Curves.easeOut);
  }
}

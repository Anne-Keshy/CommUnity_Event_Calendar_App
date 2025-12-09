import 'package:community/screens/main_screen.dart';
import 'package:community/services/auth_service.dart';
import 'package:community/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:community/theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (_isLoading) return;
    // Validate the form before proceeding
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful!"),
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
            onPressed: _login,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: context.responsivePadding,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: context.maxContentWidth,
                  ),
                  decoration: AppTheme.glassmorphismDecoration,
                  padding: EdgeInsets.all(context.isPhone ? 20.0 : 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: context.hPadding(80)),
                        Icon(
                          Icons.celebration,
                          size: context.isPhone ? 80 : 120,
                          color: Colors.white,
                        )
                            .animate()
                            .fade(duration: 1.seconds)
                            .slideY(begin: -0.5, curve: Curves.easeOut),
                        SizedBox(height: context.hPadding(20)),
                        Text(
                          "Welcome Back",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: context.fontSize(28),
                          ),
                        ),
                        Text(
                          "Sign in to continue",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: context.fontSize(14),
                          ),
                        ),
                        SizedBox(height: context.hPadding(50)),
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
                        SizedBox(height: context.hPadding(20)),
                        _buildTextField(
                            controller: _passwordController,
                            hint: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()));
                            },
                            child: Text("Forgot Password?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.fontSize(14),
                                )),
                          ),
                        ),
                        SizedBox(height: context.hPadding(20)),
                        _buildLoginButton(),
                        SizedBox(height: context.hPadding(30)),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text("Don't have an account?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.fontSize(14),
                                )),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpScreen()));
                              },
                              child: Text("Sign Up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.fontSize(14),
                                    fontWeight: FontWeight.bold,
                                  )),
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
      style: TextStyle(
        color: Colors.black,
        fontSize: context.fontSize(16),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.orange,
          fontSize: context.fontSize(14),
        ),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: AppTheme.glassWhite,
        isDense: false,
        contentPadding: EdgeInsets.symmetric(
          vertical: context.isPhone ? 12 : 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
        ),
        onPressed: _login,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("Sign In",
                style: GoogleFonts.poppins(
                    fontSize: context.fontSize(16),
                    fontWeight: FontWeight.w600)),
      ),
    )
        .animate()
        .fade(delay: 500.ms)
        .slideX(begin: 0.5, curve: Curves.easeOut);
  }
}

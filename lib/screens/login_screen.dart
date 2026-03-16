import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mycrm/core/constants/app_colors.dart';

import '../routes/app_routes.dart';

/// Login page styled to match the provided reference design.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Demo credentials used by the current placeholder login flow.
  static const String _dummyEmail = 'demo@mycrm.com';
  static const String _dummyPassword = 'crm@123';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: _dummyEmail);
  final _passwordController = TextEditingController(text: _dummyPassword);

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the form and routes to the dashboard on a successful demo login.
  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == _dummyEmail && password == _dummyPassword) {
      Get.offNamed(AppRoutes.dashboard);
      Get.snackbar(
        'Login successful',
        'Welcome back to MyCRM.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF153A63),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    Get.snackbar(
      'Invalid login',
      'Use demo@mycrm.com and crm@123',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB3261E),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF18C6D3);
    const titleOrange = Color(0xFFDB8A1E);
    const inputIcon = Color(0xFF74D8D3);
    const cardBorder = Color(0xFFE7EDF5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFB9F3F6),
                      const Color(0xFFE9FCFD),
                      Colors.white,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.18, 0.46, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x33A4F0F0), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -46,
              bottom: -42,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  width: 170,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cyan.withOpacity(0.18),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildLogo(),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryBlue,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildInputShell(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF39475A),
                              fontSize: 15,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              return null;
                            },
                            decoration: _fieldDecoration(
                              hintText: 'Username',
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                color: inputIcon,
                                size: 21,
                              ),
                              cardBorder: cardBorder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildInputShell(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF39475A),
                              fontSize: 15,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your password';
                              }
                              return null;
                            },
                            decoration: _fieldDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_rounded,
                                color: inputIcon,
                                size: 21,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFFB6C0CF),
                                  size: 21,
                                ),
                              ),
                              cardBorder: cardBorder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.poppins(
                                color: cyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF153A63), Color(0xFF16C5DC)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3316C5DC),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the app logo image from local assets.
  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png',
      height: 142,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/logo.png',
          height: 142,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 142,
              height: 142,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F7FB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.business_center_rounded,
                size: 56,
                color: Color(0xFF18C6D3),
              ),
            );
          },
        );
      },
    );
  }

  /// Adds glow/shadow styling around focused-looking fields.
  Widget _buildInputShell({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E102A43),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Shared input decoration for the login form fields.
  InputDecoration _fieldDecoration({
    required String hintText,
    required Color cardBorder,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF95A1B1),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF18C6D3), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

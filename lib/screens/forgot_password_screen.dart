import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/responsive.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      AppSnackbar.show('Reset link sent', message);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final message = _extractErrorMessage(error);

      AppSnackbar.show('Request failed', message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        'Request failed',
        'Something went wrong while sending the reset link.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const screenBackground = Color(0xFFF6F5FF);
    const cardBorder = Color(0xFFE3E6F0);
    const fieldBorder = Color(0xFFD5DBE7);
    const buttonBlue = Color(0xFF1E88E5);
    final isCompact = context.isCompactWidth;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width >= 900 ? 460 : 420,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 40,
                  vertical: isCompact ? 28 : 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(isCompact: isCompact),
                      SizedBox(height: isCompact ? 18 : 22),
                      Text(
                        'Technofra',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.style(
                          color: const Color(0xFF111827),
                          fontSize: isCompact ? 20 : 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Enter your email address and we'll send you a link\n"
                        'to reset your password',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.style(
                          color: const Color(0xFF374151),
                          fontSize: isCompact ? 14 : 15,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: isCompact ? 28 : 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: AppTextStyles.style(
                            color: const Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          return Validators.validateEmail(value?.trim());
                        },
                        onFieldSubmitted: (_) {
                          if (_isSubmitting) {
                            return;
                          }
                          _submit();
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: AppTextStyles.style(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isCompact ? 14 : 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: buttonBlue,
                              width: 1.4,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            disabledBackgroundColor: buttonBlue.withOpacity(0.7),
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(isCompact ? 46 : 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Send Reset Link',
                                  style: AppTextStyles.style(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Remember your password?',
                            style: AppTextStyles.style(
                              color: const Color(0xFF111827),
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(AppRoutes.login),
                            child: Text(
                              'Sign in here',
                              style: AppTextStyles.style(
                                color: AppColors.primaryBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
    );
  }

  Widget _buildLogo({required bool isCompact}) {
    final size = isCompact ? 56.0 : 64.0;
    return Image.asset(
      'assets/logo.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.business_center_rounded,
          size: size,
          color: AppColors.primaryBlue,
        );
      },
    );
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final errors = responseData['errors'];
      final validationMessage = _extractValidationMessage(errors);
      if (validationMessage != null) {
        return validationMessage;
      }

      final apiMessage = responseData['message'] ?? responseData['error'];
      final normalizedMessage = apiMessage?.toString().trim() ?? '';
      if (normalizedMessage.isNotEmpty) {
        return normalizedMessage;
      }
    }

    final fallbackMessage = error.message?.trim() ?? '';
    if (fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }

    return 'Unable to send reset link. Please try again.';
  }

  String? _extractValidationMessage(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is Iterable) {
      for (final item in data) {
        final message = _extractValidationMessage(item);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return null;
    }
    if (data is Map) {
      for (final value in data.values) {
        final message = _extractValidationMessage(value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }
    return null;
  }
}

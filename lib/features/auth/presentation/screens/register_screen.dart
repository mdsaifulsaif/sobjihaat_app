import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      SnackbarUtils.showError(
        context,
        'Please agree to the Terms of Service and Privacy Policy',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    if (success) {
      SnackbarUtils.showSuccess(
        context,
        authState.successMessage ?? 'Verification code sent to your email!',
      );

      final email = authState.pendingVerificationEmail ?? _emailController.text;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    } else if (authState.errorMessage != null) {
      SnackbarUtils.showError(context, authState.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(
                    size: 54,
                    subtitle: 'Join SobjiHaat to get farm-fresh groceries',
                  ),
                  const SizedBox(height: 28),

                  // Name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hintText: 'e.g. Arif',
                          validator: (val) => FormValidators.required(val, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hintText: 'e.g. Hossain',
                          validator: (val) => FormValidators.required(val, 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email
                  AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'e.g. arif@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number (Optional)
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone Number (Optional)',
                    hintText: 'e.g. 01700000000',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: FormValidators.phone,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Minimum 6 characters',
                    isPassword: true,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: FormValidators.password,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: (val) => FormValidators.confirmPassword(
                      val,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Terms & Conditions checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service & Privacy Policy',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  AppButton(
                    text: 'Create Account',
                    isLoading: authState.isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Sign In',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

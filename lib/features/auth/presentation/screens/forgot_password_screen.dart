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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).forgotPassword(
          email: _emailController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    if (success) {
      setState(() {
        _emailSent = true;
      });
      SnackbarUtils.showSuccess(
        context,
        authState.successMessage ?? 'Reset instructions sent to your email!',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _emailSent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.primary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Check Your Email',
                        style: AppTypography.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We have sent a password reset link to ${_emailController.text}. Please follow the link in your email to reset your password.',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      AppButton(
                        text: 'Back to Sign In',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppLogo(size: 60, showText: false),
                        const SizedBox(height: 20),
                        Text(
                          'Forgot Password?',
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your registered email address and we will send you a password reset link.',
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'e.g. user@shobjihaat.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: 28),
                        AppButton(
                          text: 'Send Reset Link',
                          isLoading: authState.isLoading,
                          onPressed: _handleForgotPassword,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'Return to Sign In',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

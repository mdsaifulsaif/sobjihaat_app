import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _pinController.text.trim();
    if (code.length < 6) {
      SnackbarUtils.showError(context, 'Please enter the complete 6-digit code');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).verifyEmail(
          email: widget.email,
          code: code,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    if (success) {
      SnackbarUtils.showSuccess(context, 'Email verified successfully!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (authState.errorMessage != null) {
      SnackbarUtils.showError(context, authState.errorMessage!);
    }
  }

  Future<void> _handleResendCode() async {
    if (_countdown > 0) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendVerificationEmail(email: widget.email);

    if (!mounted) return;

    if (success) {
      SnackbarUtils.showSuccess(
        context,
        'A fresh verification code has been sent to ${widget.email}',
      );
      _startCountdown();
    } else {
      final authState = ref.read(authNotifierProvider);
      SnackbarUtils.showError(
        context,
        authState.errorMessage ?? 'Failed to resend code',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: AppTypography.headlineMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
    );

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 60, showText: false),
                const SizedBox(height: 20),

                Text(
                  'Verify Your Email',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'We have sent a 6-digit verification code to:',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                Text(
                  widget.email,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Pinput Field
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _pinController,
                    focusNode: _focusNode,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    keyboardType: TextInputType.number,
                    onCompleted: (_) => _handleVerify(),
                  ),
                ),
                const SizedBox(height: 32),

                // Verify Button
                AppButton(
                  text: 'Verify & Continue',
                  isLoading: authState.isLoading,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 24),

                // Resend Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: AppTypography.bodyMedium,
                    ),
                    if (_countdown > 0)
                      Text(
                        'Resend in ${_countdown}s',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleResendCode,
                        child: Text(
                          'Resend Code',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

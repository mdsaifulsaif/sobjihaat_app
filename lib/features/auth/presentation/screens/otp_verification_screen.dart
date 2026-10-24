import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../home/presentation/screens/main_nav_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

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
  late final TextEditingController _emailEditController;

  late String _currentEmail;
  bool _isEditingEmail = false;
  int _countdown = 30;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email.trim();
    _emailEditController = TextEditingController(text: _currentEmail);
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
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
    _emailEditController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final trimmedEmail = _currentEmail.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your email address.');
      setState(() => _isEditingEmail = true);
      return;
    }

    final code = _pinController.text.trim();
    if (code.length != 6) {
      SnackbarUtils.showError(context, 'Please enter the complete 6-digit code');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).verifyEmail(
          email: trimmedEmail,
          code: code,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    if (success) {
      SnackbarUtils.showSuccess(
        context,
        'Email verified successfully! Welcome to SobjiHaat 🎉',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else if (authState.errorMessage != null) {
      SnackbarUtils.showError(context, authState.errorMessage!);
    }
  }

  Future<void> _handleResendCode() async {
    final trimmedEmail = _currentEmail.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your email address first.');
      setState(() => _isEditingEmail = true);
      return;
    }

    if (_countdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendVerificationEmail(email: trimmedEmail);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _pinController.clear();
      _startCountdown();
      SnackbarUtils.showSuccess(
        context,
        'A fresh 6-digit verification code has been sent!',
      );
    } else {
      final authState = ref.read(authNotifierProvider);
      SnackbarUtils.showError(
        context,
        authState.errorMessage ?? 'Failed to resend verification code',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email Icon Badge (Exact match to web VerifyEmailPage)
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mail_outline_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Description
                  Text(
                    'Verify Your Email',
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'We have sent a 6-digit verification code to',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Email Display & Edit Box (Exact match to web VerifyEmailPage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isEditingEmail
                              ? TextField(
                                  controller: _emailEditController,
                                  autofocus: true,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Enter your email',
                                  ),
                                )
                              : Text(
                                  _currentEmail,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (_isEditingEmail) {
                              final text = _emailEditController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _currentEmail = text;
                                  _isEditingEmail = false;
                                });
                              }
                            } else {
                              setState(() {
                                _isEditingEmail = true;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isEditingEmail
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.edit_outlined,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isEditingEmail ? 'Done' : 'Change',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Label: Enter 6-digit code
                  const Text(
                    'ENTER 6-DIGIT CODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 100% Native 6-Box OTP Input (Immune to Flutter 3.47 Material bugs)
                  Center(
                    child: _NativeOtp6BoxInput(
                      controller: _pinController,
                      focusNode: _focusNode,
                      onCompleted: (_) => _handleVerify(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Expiration Note
                  Text(
                    'The code expires in 10 minutes. Check your spam folder if not received.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Verify & Sign In Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Verify & Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend Code Button with Countdown
                  OutlinedButton.icon(
                    onPressed: (_countdown > 0 || _isResending) ? null : _handleResendCode,
                    icon: _isResending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF64748B),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _countdown > 0
                          ? 'Resend code in ${_countdown}s'
                          : _isResending
                              ? 'Sending new code...'
                              : 'Resend Code',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Navigation Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          '← Register again',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Back to Sign In →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

/// 100% Native 6-Box OTP Input component (Identical to website /verify-email)
class _NativeOtp6BoxInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onCompleted;

  const _NativeOtp6BoxInput({
    required this.controller,
    required this.focusNode,
    this.onCompleted,
  });

  @override
  State<_NativeOtp6BoxInput> createState() => _NativeOtp6BoxInputState();
}

class _NativeOtp6BoxInputState extends State<_NativeOtp6BoxInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == 6) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasFocus = widget.focusNode.hasFocus;

    return Stack(
      children: [
        // Visual 6 rounded boxes matching web design
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final hasChar = index < text.length;
            final isCurrent = hasFocus && (index == text.length || (index == 5 && text.length == 6));
            final char = hasChar ? text[index] : '';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary
                      : hasChar
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                  width: isCurrent ? 2.0 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                hasChar ? char : (isCurrent ? '|' : '•'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: hasChar
                      ? const Color(0xFF0F172A)
                      : isCurrent
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                ),
              ),
            );
          }),
        ),

        // Invisible TextField positioned over the 6 boxes for native keyboard & paste support
        Positioned.fill(
          child: Opacity(
            opacity: 0.0,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              showCursor: false,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

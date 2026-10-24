import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({
    super.key,
    this.initialToken,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength logic matching website getStrength()
  Map<String, dynamic> _getStrength(String pw) {
    if (pw.isEmpty) return {'level': 0, 'label': '', 'color': const Color(0xFF94A3B8)};
    int score = 0;
    if (pw.length >= 6) score++;
    if (pw.length >= 10 && RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (pw.length >= 10 && RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;

    if (score <= 1) return {'level': 1, 'label': 'Weak', 'color': const Color(0xFFEF4444)};
    if (score == 2) return {'level': 2, 'label': 'Okay', 'color': const Color(0xFFF59E0B)};
    return {'level': 3, 'label': 'Strong', 'color': const Color(0xFF22C55E)};
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      SnackbarUtils.showError(context, 'Reset token is required');
      return;
    }

    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 6) {
      SnackbarUtils.showError(context, 'Password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      SnackbarUtils.showError(context, 'Passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).resetPassword(
          token: token,
          newPassword: newPassword,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    if (success) {
      setState(() => _isSuccess = true);
      SnackbarUtils.showSuccess(
        context,
        authState.successMessage ?? 'Password reset successfully!',
      );
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    } else if (authState.errorMessage != null) {
      SnackbarUtils.showError(context, authState.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final strength = _getStrength(_passwordController.text);

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
      body: Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _isSuccess
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Password Updated',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your password has been reset. Taking you to login…',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Icon & Title matching website
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Set a New Password',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Choose a strong password you haven\'t used before.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Token input field (if not provided via deep link)
                            if (widget.initialToken == null || widget.initialToken!.isEmpty) ...[
                              const Text(
                                'RESET TOKEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _tokenController,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Paste token from reset email',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Enter reset token' : null,
                              ),
                              const SizedBox(height: 18),
                            ],

                            // New Password Field
                            const Text(
                              'NEW PASSWORD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                            ),

                            // Password Strength Bar (Matching website)
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (int i = 0; i < 3; i++)
                                    Expanded(
                                      child: Container(
                                        height: 4,
                                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                        decoration: BoxDecoration(
                                          color: i < (strength['level'] as int)
                                              ? (strength['color'] as Color)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    strength['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: strength['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),

                            // Confirm Password Field
                            const Text(
                              'CONFIRM NEW PASSWORD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Confirm password is required';
                                if (val != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Reset Password Button
                            AppButton(
                              text: 'Reset Password',
                              isLoading: authState.isLoading,
                              backgroundColor: const Color(0xFF0F172A),
                              onPressed: _handleResetPassword,
                            ),
                            const SizedBox(height: 20),

                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  'Back to login',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
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
        ),
      ),
    );
  }
}

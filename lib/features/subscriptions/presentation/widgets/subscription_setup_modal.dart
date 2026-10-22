import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/models/subscription_package_model.dart';

class SubscriptionSetupModal extends ConsumerStatefulWidget {
  final SubscriptionPackageModel package;

  const SubscriptionSetupModal({
    super.key,
    required this.package,
  });

  static void show(BuildContext context, SubscriptionPackageModel package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => SubscriptionSetupModal(package: package),
    );
  }

  @override
  ConsumerState<SubscriptionSetupModal> createState() =>
      _SubscriptionSetupModalState();
}

class _SubscriptionSetupModalState extends ConsumerState<SubscriptionSetupModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedFrequency = 'monthly';
  String _selectedDeliverySlot = '1st to 3rd of every month';
  bool _isLoading = false;

  final List<String> _monthlySlots = [
    '1st to 3rd of every month',
    '5th to 7th of every month',
    'Mid-Month (15th - 18th)',
    '25th to 28th of every month',
  ];

  final List<String> _weeklySlots = [
    'Every Friday morning',
    'Every Saturday morning',
    'Every Sunday morning',
    'Every Tuesday morning',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.package.frequency == 'weekly' ? 'weekly' : 'monthly';
    _selectedDeliverySlot = _selectedFrequency == 'weekly' ? _weeklySlots.first : _monthlySlots.first;

    // Auto-fill from authenticated user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      final user = authState.user;
      if (user != null) {
        _nameController.text = user.fullName;
        if (user.phoneNumber != null) _phoneController.text = user.phoneNumber!;
        if (user.shippingAddress?.addressLine != null) {
          _addressController.text = user.shippingAddress!.addressLine!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) {
      Navigator.pop(context);
      SnackbarUtils.showInfo(context, 'Please login to setup your subscription');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please fill in all recipient and delivery details');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pop(context);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text('Subscription Scheduled!', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.package.name} will be delivered on $_selectedDeliverySlot with Cash on Delivery per delivery cycle.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'OK, Great!',
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Handle & Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscribe to ${widget.package.name}',
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '৳${widget.package.subscriptionPrice.toInt()} / ${widget.package.frequency}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            if (!authState.isAuthenticated) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sign in to automatically pre-fill your delivery details.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preferred Delivery Slot
            Text(
              'Preferred Delivery Cycle',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDeliverySlot,
                  isExpanded: true,
                  items: (_selectedFrequency == 'weekly' ? _weeklySlots : _monthlySlots)
                      .map(
                        (slot) => DropdownMenuItem(
                          value: slot,
                          child: Text(slot, style: AppTypography.bodyMedium),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDeliverySlot = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pre-filled Recipient Name
            AppTextField(
              controller: _nameController,
              label: 'Customer Name',
              hintText: 'e.g. Arif Hossain',
            ),
            const SizedBox(height: 14),

            // Phone
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'e.g. 01700000000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // Address
            AppTextField(
              controller: _addressController,
              label: 'Delivery Address',
              hintText: 'e.g. House 12, Road 4, Dhanmondi, Dhaka',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Payment Notice (Strict COD)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment: Cash on Delivery (COD)',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Pay per delivery cycle after inspecting fresh items.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppButton(
              text: 'Confirm Subscription',
              isLoading: _isLoading,
              onPressed: _handleConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

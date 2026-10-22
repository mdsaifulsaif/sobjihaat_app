import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/coupon_model.dart';
import '../providers/cart_provider.dart';

class AvailableCouponsBottomSheet extends ConsumerStatefulWidget {
  final double currentSubtotal;
  final ValueChanged<String>? onApplyCoupon;
  final VoidCallback? onManualCodeRequested;

  const AvailableCouponsBottomSheet({
    super.key,
    required this.currentSubtotal,
    this.onApplyCoupon,
    this.onManualCodeRequested,
  });

  static Future<void> show(
    BuildContext context, {
    required double currentSubtotal,
    ValueChanged<String>? onApplyCoupon,
    VoidCallback? onManualCodeRequested,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvailableCouponsBottomSheet(
        currentSubtotal: currentSubtotal,
        onApplyCoupon: onApplyCoupon,
        onManualCodeRequested: onManualCodeRequested,
      ),
    );
  }

  @override
  ConsumerState<AvailableCouponsBottomSheet> createState() =>
      _AvailableCouponsBottomSheetState();
}

class _AvailableCouponsBottomSheetState
    extends ConsumerState<AvailableCouponsBottomSheet> {
  List<CouponModel> _coupons = [];
  bool _isLoading = true;
  String? _error;
  String? _copiedCode;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authNotifierProvider).user;
      final dataSource = ref.read(cartRemoteDataSourceProvider);
      final list = await dataSource.getAvailableCoupons(userId: user?.id);
      if (mounted) {
        setState(() {
          _coupons = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'কুপন লোড করা যায়নি। অনুগ্রহ করে পুনরায় চেষ্টা করুন।';
          _isLoading = false;
        });
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCode = code);
    SnackbarUtils.showSuccess(context, 'কুপন কোড $code কপি করা হয়েছে! 🎟️');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCode = null);
    });
  }

  void _applyCoupon(String code) {
    if (widget.onApplyCoupon != null) {
      widget.onApplyCoupon!(code);
    } else {
      final user = ref.read(authNotifierProvider).user;
      ref.read(cartNotifierProvider.notifier).applyCoupon(code, userId: user?.id);
    }
    Navigator.pop(context);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'সীমিত সময়ের জন্য (Limited time)';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final appliedCode = cartState.appliedCoupon?.code;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header (Matching web AvailableCouponsDrawer.tsx)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Coupons',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isLoading
                              ? 'Checking offers...'
                              : _coupons.isEmpty
                                  ? 'No active offers available'
                                  : '${_coupons.length} offer${_coupons.length == 1 ? "" : "s"} available for you',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Coupons List Content / Clear Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchCoupons,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _coupons.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Center(
                                      child: Text('🎟️', style: TextStyle(fontSize: 34)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'বর্তমানে কোনো কুপন সক্রিয় নেই',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'No Active Coupons Available',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Text(
                                      'এই মুহূর্তে সর্বসাধারণের জন্য কোনো উন্মুক্ত কুপন চালু নেই। তবে আপনার কাছে কোনো বিশেষ প্রোমো কোড থাকলে চেকআউট পেজের কুপন বক্সে লিখে সরাসরি Apply বাটনে চাপুন।',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.45,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        widget.onManualCodeRequested?.call();
                                      },
                                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                                      label: const Text(
                                        'প্রোমো কোড সরাসরি লিখুন',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: _fetchCoupons,
                                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
                                    label: const Text(
                                      'আবার চেক করুন (Refresh)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _coupons.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final coupon = _coupons[index];
                              final isApplied = appliedCode != null &&
                                  appliedCode.toUpperCase() == coupon.code.toUpperCase();
                              final isEligible = coupon.isEligibleForAmount(widget.currentSubtotal);
                              final remaining = isEligible
                                  ? 0
                                  : (coupon.minPurchase - widget.currentSubtotal).toInt();

                              return _buildCouponCard(
                                coupon: coupon,
                                isApplied: isApplied,
                                isEligible: isEligible,
                                remaining: remaining,
                              );
                            },
                          ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: const Text(
              'Coupons are automatically validated against your order at checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard({
    required CouponModel coupon,
    required bool isApplied,
    required bool isEligible,
    required int remaining,
  }) {
    // Scope label
    String scopeBadge = 'সকল পণ্যের জন্য';
    Color scopeBg = const Color(0xFFF0FDFA);
    Color scopeColor = const Color(0xFF0F766E);
    Color scopeBorder = const Color(0xFFCCFBF1);

    if (coupon.applicableTo == 'specific_categories') {
      scopeBadge = 'নির্দিষ্ট ক্যাটাগরি';
      scopeBg = const Color(0xFFFAF5FF);
      scopeColor = const Color(0xFF7E22CE);
      scopeBorder = const Color(0xFFF3E8FF);
    } else if (coupon.applicableTo == 'specific_users') {
      scopeBadge = '🌟 আপনার জন্য স্পেশাল অফার';
      scopeBg = const Color(0xFFF0FDF4);
      scopeColor = const Color(0xFF15803D);
      scopeBorder = const Color(0xFFDCFCE7);
    }

    return Container(
      decoration: BoxDecoration(
        color: isApplied ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApplied ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isApplied ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Discount Badge + Scope Badge + Code Pill with copy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.discountBadgeText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (coupon.isPercentage && coupon.maxDiscount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Up to ৳${coupon.maxDiscount.toInt()}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scopeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: scopeBorder),
                      ),
                      child: Text(
                        scopeBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scopeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Coupon Code pill with 1-tap copy
              GestureDetector(
                onTap: () => _copyCode(coupon.code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _copiedCode == coupon.code
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        size: 13,
                        color: _copiedCode == coupon.code
                            ? AppColors.primary
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Coupon Title / Name
          if (coupon.name.isNotEmpty)
            Text(
              coupon.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),

          if (coupon.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              coupon.description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Condition & Expiry
          Row(
            children: [
              if (coupon.minPurchase > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Min. Order: ৳${coupon.minPurchase.toInt()}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                'Valid till ${_formatDate(coupon.endDate)}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Bottom Action: Applied OR Add More OR Apply Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isEligible && remaining > 0)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Add ৳$remaining more to apply',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isApplied)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF15803D)),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Coupon Applied (Active)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Flexible(
                  child: Text(
                    'Eligible on current cart',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Button
              if (isApplied)
                TextButton(
                  onPressed: () {
                    ref.read(cartNotifierProvider.notifier).removeCoupon();
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: isEligible ? () => _applyCoupon(coupon.code) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Coupon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../providers/cart_provider.dart';
import '../screens/checkout_screen.dart';
import 'available_coupons_bottom_sheet.dart';

class MiniCartBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onProceedToCheckout;
  final String? checkoutButtonText;

  const MiniCartBottomSheet({
    super.key,
    this.onProceedToCheckout,
    this.checkoutButtonText,
  });

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MiniCartBottomSheet(
        onProceedToCheckout: () {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<MiniCartBottomSheet> createState() => _MiniCartBottomSheetState();
}

class _MiniCartBottomSheetState extends ConsumerState<MiniCartBottomSheet> {
  final TextEditingController _couponController = TextEditingController();
  bool _showCouponInput = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _handleApplyCoupon([String? directCode]) {
    final code = directCode ?? _couponController.text.trim();
    if (code.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter a coupon code');
      return;
    }
    ref.read(cartNotifierProvider.notifier).applyCoupon(code).then((success) {
      if (mounted) {
        if (success) {
          _couponController.clear();
          setState(() => _showCouponInput = false);
          SnackbarUtils.showSuccess(context, 'Coupon applied! 🎉');
        } else {
          final err = ref.read(cartNotifierProvider).couponError ?? 'Invalid coupon';
          SnackbarUtils.showError(context, err);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final items = cartState.items;
    final subtotal = cartState.subtotal;
    final couponDiscount = cartState.couponDiscount;
    final totalPayable = cartState.totalPayable;

    final isFreeShipping = subtotal >= 1000;
    final neededForFreeShipping = (1000 - subtotal).toInt();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top bar: Delivery charge notice (Matching web MiniCart line 40)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Text(
                'Delivery charge not included',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 2. Header (Matching web MiniCart lines 45-65)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cartState.totalCount} ${cartState.totalCount == 1 ? "Item" : "Items"} in Cart',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isFreeShipping ? 'Shipping Fee: ৳0' : 'Shipping Fee: ৳60 (Free over ৳1000)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_double_arrow_right_rounded, color: Color(0xFF64748B), size: 24),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close Cart',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 3. Smart Upsell Nudge Bar (Matching web SmartUpsellNudge)
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isFreeShipping ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              child: Row(
                children: [
                  Icon(
                    isFreeShipping ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                    size: 16,
                    color: isFreeShipping ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFreeShipping
                          ? '🎉 FREE Delivery unlocked on this order!'
                          : 'Add ৳$neededForFreeShipping more for FREE Delivery in Barisal!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isFreeShipping ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Items List (Matching web MiniCart.tsx lines 68-135)
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, size: 36, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Looks like you haven\'t added any vegetables or groceries yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.storefront_rounded, size: 16),
                            label: const Text('Start Shopping', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final product = item.product;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail (web image wrapper 56x56)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: product.thumbnail.isNotEmpty
                                ? Image.network(
                                    product.thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.eco_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  )
                                : const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),

                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Price & MRP strike-through
                                Row(
                                  children: [
                                    Text(
                                      '৳${product.effectivePrice.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (product.hasDiscount) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '৳${product.regularPrice.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Quantity Controls & Delete
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Circular Stepper (Matching web rounded-full border border-gray-200)
                                    Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              ref.read(cartNotifierProvider.notifier).updateQuantity(
                                                    product.id,
                                                    item.quantity - 1,
                                              );
                                            },
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Text('−', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              ref.read(cartNotifierProvider.notifier).updateQuantity(
                                                    product.id,
                                                    item.quantity + 1,
                                              );
                                            },
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Trash Icon
                                    InkWell(
                                      onTap: () {
                                        ref.read(cartNotifierProvider.notifier).removeFromCart(product.id);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // 5. Special code & Coupon Drawer Trigger (Matching web MiniCart.tsx lines 138-142)
          if (items.isNotEmpty) ...[
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: cartState.appliedCoupon != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFFF0FDF4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF15803D)),
                              const SizedBox(width: 6),
                              Text(
                                '${cartState.appliedCoupon!.code} (-৳${couponDiscount.toInt()})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(cartNotifierProvider.notifier).removeCoupon();
                            },
                            child: const Text('Remove', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          ),
                        ],
                      ),
                    )
                  : _showCouponInput
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _couponController,
                                    textCapitalization: TextCapitalization.characters,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter coupon code',
                                      hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: cartState.isApplyingCoupon ? null : () => _handleApplyCoupon(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text('Apply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                                onPressed: () => setState(() => _showCouponInput = false),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            AvailableCouponsBottomSheet.show(
                              context,
                              currentSubtotal: subtotal,
                              onApplyCoupon: (code) => _handleApplyCoupon(code),
                              onManualCodeRequested: () => setState(() => _showCouponInput = true),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            color: const Color(0xFFF8FAFC),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.local_offer_outlined, size: 14, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  '⌃ View Available Coupons & Promo Codes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),

            // 6. Footer: Proceed to Checkout Button (Matching web MiniCart.tsx lines 143-150)
            InkWell(
              onTap: () {
                if (widget.onProceedToCheckout != null) {
                  widget.onProceedToCheckout!();
                } else {
                  final nav = Navigator.of(context, rootNavigator: true);
                  nav.pop();
                  nav.push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                color: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.checkoutButtonText ?? 'Proceed to Checkout',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          widget.checkoutButtonText != null
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      '৳${totalPayable.toInt()}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/wishlist_provider.dart';
import 'product_quick_view_modal.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;
  final int cartQuantity;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.cartQuantity = 0,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isStepperOpen = false;

  void _handleAddToCart() {
    HapticFeedback.lightImpact();
    ref.read(cartNotifierProvider.notifier).addToCart(widget.product, 1);
    ref.read(wishlistProvider.notifier).addToRecentlyViewed(widget.product);
    if (widget.onAddToCart != null) {
      widget.onAddToCart!();
    }
    setState(() {});
    SnackbarUtils.showSuccess(context, 'Added ${widget.product.name} to cart 🛍️');
  }

  void _handleIncrement() {
    HapticFeedback.selectionClick();
    final current = ref.read(cartNotifierProvider).getQuantity(widget.product.id);
    ref.read(cartNotifierProvider.notifier).updateQuantity(widget.product.id, current + 1);
    setState(() {});
  }

  void _handleDecrement() {
    HapticFeedback.selectionClick();
    final current = ref.read(cartNotifierProvider).getQuantity(widget.product.id);
    if (current <= 1) {
      setState(() => _isStepperOpen = false);
    }
    ref.read(cartNotifierProvider.notifier).updateQuantity(widget.product.id, current - 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.isWishlisted(product.id);
    final cartState = ref.watch(cartNotifierProvider);
    final quantity = cartState.getQuantity(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Container with Badges & Buttons
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                // Product Image (Tapping opens Quick View)
                Positioned.fill(
                  child: InkWell(
                    onTap: () {
                      ref.read(wishlistProvider.notifier).addToRecentlyViewed(product);
                      ProductQuickViewModal.show(context, product);
                    },
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: product.thumbnail.isNotEmpty
                            ? Image.network(
                                product.thumbnail,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                              ),
                      ),
                    ),
                  ),
                ),

                // Top-Left: Discount Badge (e.g. 6% OFF / 20% OFF)
                if (product.hasDiscount)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.computedDiscountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                // Top-Right: Wishlist Heart Outline Icon Button
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      final added = ref.read(wishlistProvider.notifier).toggleWishlist(product);
                      SnackbarUtils.showInfo(
                        context,
                        added ? 'Added to Wishlist ❤️' : 'Removed from Wishlist',
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? Colors.red : const Color(0xFF94A3B8),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom-Right: Add to Cart Button / Quantity Box (Matches Web Screenshot 2 & 3!)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: quantity == 0
                      // Not in Cart: White squircle with green border and green plus '+'
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleAddToCart,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary, width: 1.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _isStepperOpen
                          // Stepper expanded: [-] [qty] [+]
                          ? Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary, width: 1.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _handleDecrement,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      child: Icon(Icons.remove, size: 15, color: AppColors.primary),
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _handleIncrement,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      child: Icon(Icons.add, size: 15, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // Already in Cart: Solid green squircle with white quantity number (Exact match to Image 3!)
                          : Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _isStepperOpen = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),

          // Details Container (Tapping also opens Quick View)
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () {
                ref.read(wishlistProvider.notifier).addToRecentlyViewed(product);
                ProductQuickViewModal.show(context, product);
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Row: ৳44  ৳47
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '৳${product.effectivePrice.toInt()}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 4),
                              Text(
                                '৳${product.regularPrice.toInt()}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Title: e.g. "Cucumber ± 50 gm"
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Bottom Row: Rating ★ 4 on left, Unit 1 pc on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              '0',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.weightOrVolume != null || product.unitName != null
                                ? '${product.weightOrVolume?.toInt() ?? ''} ${product.unitName ?? ''}'.trim()
                                : '1 pc',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF64748B),
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
        ],
      ),
    );
  }
}

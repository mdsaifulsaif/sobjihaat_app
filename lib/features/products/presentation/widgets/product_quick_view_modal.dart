import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/wishlist_provider.dart';

class ProductQuickViewModal extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductQuickViewModal({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductQuickViewModal(product: product),
    );
  }

  @override
  ConsumerState<ProductQuickViewModal> createState() => _ProductQuickViewModalState();
}

class _ProductQuickViewModalState extends ConsumerState<ProductQuickViewModal> {
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    final cartState = ref.read(cartNotifierProvider);
    final inCartQty = cartState.getQuantity(widget.product.id);
    _selectedQuantity = inCartQty > 0 ? inCartQty : 1;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.isWishlisted(product.id);
    final cartState = ref.watch(cartNotifierProvider);
    final inCartQty = cartState.getQuantity(product.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Drag handle & close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with Discount Tag & Wishlist button
                  Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.thumbnail.isNotEmpty
                              ? Image.network(
                                  product.thumbnail,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
                                ),
                        ),
                      ),
                      if (product.hasDiscount)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.discountBadge,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${product.computedDiscountPercent}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InkWell(
                          onTap: () {
                            final added = ref.read(wishlistProvider.notifier).toggleWishlist(product);
                            SnackbarUtils.showInfo(
                              context,
                              added ? 'Added to Wishlist ❤️' : 'Removed from Wishlist',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isWishlisted ? Colors.red : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Meta
                  Text(
                    product.name,
                    style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // Star rating
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('4.8', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('(120+ reviews)', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                      const Spacer(),
                      // Stock status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: product.stock > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.stock > 0 ? 'In Stock (${product.stock})' : 'Out of Stock',
                          style: TextStyle(
                            color: product.stock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Pricing row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '৳${product.effectivePrice.toInt()}',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          '৳${product.regularPrice.toInt()}',
                          style: AppTypography.bodyLarge.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (product.weightOrVolume != null || product.unitName != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '/ ${product.weightOrVolume?.toInt() ?? ''} ${product.unitName ?? ''}'.trim(),
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 28, color: AppColors.border),

                  // Organic / Delivery Highlights
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHighlight(Icons.eco_rounded, '100% Organic', 'Direct from farms'),
                      _buildHighlight(Icons.speed_rounded, 'Same Day', 'Express delivery'),
                      _buildHighlight(Icons.verified_user_outlined, 'Quality Check', 'Triple graded'),
                    ],
                  ),
                  const Divider(height: 28, color: AppColors.border),

                  // Description
                  Text('Description', style: AppTypography.headlineMedium.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    product.shortDescription ??
                        'Freshly sourced premium vegetables, pesticide-free, graded for optimal freshness and delivered in eco-friendly packaging within Dhaka city.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Stepper
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _selectedQuantity > 1
                            ? () => setState(() => _selectedQuantity--)
                            : null,
                      ),
                      Text(
                        '$_selectedQuantity',
                        style: AppTypography.headlineMedium.copyWith(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _selectedQuantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).addToCart(product, _selectedQuantity);
                      Navigator.pop(context);
                      SnackbarUtils.showSuccess(
                        context,
                        'Added $_selectedQuantity x ${product.name} to cart 🛍️',
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          inCartQty > 0 ? 'Update Cart (৳${(product.effectivePrice * _selectedQuantity).toInt()})' : 'Add to Cart (৳${(product.effectivePrice * _selectedQuantity).toInt()})',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

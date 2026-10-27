import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExplore;

  const WishlistScreen({super.key, this.onExplore});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);
    final wishlist = wishlistState.wishlist;
    final recentlyViewed = wishlistState.recentlyViewed;
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Wishlist & History', style: AppTypography.headlineMedium),
        centerTitle: false,
        actions: [
          if (wishlist.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(wishlistProvider.notifier).clearWishlist();
                SnackbarUtils.showInfo(context, 'Wishlist cleared');
              },
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 18),
              label: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 6),
                  Text('Wishlist (${wishlist.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Recent (${recentlyViewed.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Wishlist Tab
          wishlist.isEmpty
              ? _buildEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Your wishlist is empty',
                  subtitle: 'Tap the heart ❤️ icon on any product to save it for later.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: wishlist.length,
                  itemBuilder: (context, index) {
                    final product = wishlist[index];
                    return ProductCard(
                      product: product,
                      cartQuantity: cartState.getQuantity(product.id),
                      onAddToCart: () {
                        ref.read(cartNotifierProvider.notifier).addToCart(product);
                        SnackbarUtils.showSuccess(context, 'Added ${product.name} to cart');
                      },
                    );
                  },
                ),

          // Recently Viewed Tab ("so product a ami ki ki dekhechi")
          recentlyViewed.isEmpty
              ? _buildEmptyState(
                  icon: Icons.visibility_outlined,
                  title: 'No recently viewed items',
                  subtitle: 'Products you inspect will automatically appear here for quick access.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: recentlyViewed.length,
                  itemBuilder: (context, index) {
                    final product = recentlyViewed[index];
                    return ProductCard(
                      product: product,
                      cartQuantity: cartState.getQuantity(product.id),
                      onAddToCart: () {
                        ref.read(cartNotifierProvider.notifier).addToCart(product);
                        SnackbarUtils.showSuccess(context, 'Added ${product.name} to cart');
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.headlineMedium.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onExplore,
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text('Browse Products', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

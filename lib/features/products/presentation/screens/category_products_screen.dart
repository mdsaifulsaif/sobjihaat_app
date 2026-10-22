import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../../core/widgets/sobjihaat_header.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../home/data/models/category_model.dart';
import '../providers/category_products_provider.dart';
import '../widgets/product_card.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 250)) {
      ref.read(categoryProductsProvider(widget.category.slug).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProductsProvider(widget.category.slug));
    final cartState = ref.watch(cartNotifierProvider);

    // Calculate exact card dimensions identical to HomeScreen (height: 195, padding: 14, spacing: 8)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 28 - (8 * 2)) / 3;
    final cardAspectRatio = cardWidth / 195;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // 1. Fixed Top Header (SobjiHaat Brand Logo + Search Pill - Image 2)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: SobjiHaatHeader(
          showBackButton: true,
          onBackTap: () => Navigator.of(context).maybePop(),
          searchController: _searchController,
          hintText: 'Search in ${widget.category.name}...',
        ),
      ),
      // 2. Fixed Center Elevated Shopping Bag Floating Button (Image 1)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: buildSobjiHaatFloatingCartButton(context, ref),
      // 3. Fixed Bottom Navigation Bar (Home, Category, Wishlist, Profile - Image 1)
      bottomNavigationBar: buildSobjiHaatBottomAppBar(
        context,
        ref,
        currentIndex: 1, // Category active
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).maybePop();
          }
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(categoryProductsProvider(widget.category.slug).notifier).refresh();
        },
        child: _buildBody(state, cartState, cardAspectRatio),
      ),
    );
  }

  Widget _buildBody(CategoryProductsState state, CartState cartState, double cardAspectRatio) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildSkeletonGrid(cardAspectRatio);
    }

    if (state.error != null && state.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Failed to load products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.error ?? 'Something went wrong. Please check your connection.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(categoryProductsProvider(widget.category.slug).notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (!state.isLoading && state.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No products available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'There are currently no products under "${widget.category.name}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        // Category Title & Count Breadcrumb Strip
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.category.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      color: const Color(0xFFF8FAFC),
                      child: Image.network(
                        widget.category.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                if (widget.category.image.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${state.total} ${state.total == 1 ? "Product" : "Products"} found',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.total}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Product Grid: EXACTLY Same Card, Size, and Spacing as HomeScreen
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Exactly 3 cards per row
              crossAxisSpacing: 8, // Exactly 8px horizontal spacing matching HomeScreen
              mainAxisSpacing: 8, // Exactly 8px vertical spacing
              childAspectRatio: cardAspectRatio, // Exact card width / 195 height ratio
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.products[index];
                return ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  cartQuantity: cartState.getQuantity(product.id),
                );
              },
              childCount: state.products.length,
            ),
          ),
        ),

        // Infinite Scroll Bottom Indicator / End of List Footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: state.isLoadingMore
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading more products...',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    )
                  : (!state.hasMore && state.products.isNotEmpty)
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                              SizedBox(width: 6),
                              Text(
                                'All products loaded',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ),

        // Bottom space so items don't collide with BottomAppBar
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid(double cardAspectRatio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GridView.builder(
        itemCount: 9,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: cardAspectRatio,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14,
                      width: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

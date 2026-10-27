import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../../core/widgets/sobjihaat_drawer.dart';
import '../../../../core/widgets/sobjihaat_header.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/search_products_provider.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  final String? filter;
  final String? productType;
  final String? brand;
  final String? customTitle;

  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.filter,
    this.productType,
    this.brand,
    this.customTitle,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;
  late String _currentQuery;

  SearchQueryArgs get _currentArgs => SearchQueryArgs(
        query: _currentQuery,
        filter: _currentQuery.isNotEmpty ? null : widget.filter,
        productType: _currentQuery.isNotEmpty ? null : widget.productType,
        brand: _currentQuery.isNotEmpty ? null : widget.brand,
      );

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery.trim();
    _searchController = TextEditingController(text: _currentQuery);
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
      ref.read(searchProductsProvider(_currentArgs).notifier).loadMore();
    }
  }

  void _handleNewSearch(String query) {
    final trimmed = query.trim();
    if (trimmed == _currentQuery) return;
    setState(() {
      _currentQuery = trimmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProductsProvider(_currentArgs));
    final cartState = ref.watch(cartNotifierProvider);

    // Calculate exact card dimensions identical to HomeScreen (height: 195, padding: 14, spacing: 8)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 28 - (8 * 2)) / 3;
    final cardAspectRatio = cardWidth / 195;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SobjiHaatDrawer(),
      backgroundColor: Colors.white,
      // 1. Fixed Top Header (Exact match to SobjiHaat global topbar & web)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: SobjiHaatHeader(
          searchController: _searchController,
          hintText: 'Search products, categories...',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onSearchSubmitted: _handleNewSearch,
        ),
      ),
      // 2. Fixed Center Elevated Shopping Bag Floating Button (Image 1)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: buildSobjiHaatFloatingCartButton(context, ref),
      // 3. Fixed Bottom Navigation Bar (Image 1)
      bottomNavigationBar: buildSobjiHaatBottomAppBar(
        context,
        ref,
        currentIndex: 0,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(searchProductsProvider(_currentArgs).notifier).refresh();
        },
        child: _buildBody(state, cartState, cardAspectRatio),
      ),
    );
  }

  Widget _buildBody(SearchProductsState state, CartState cartState, double cardAspectRatio) {
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
                    'Failed to search products',
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
                      ref.read(searchProductsProvider(_currentArgs).notifier).refresh();
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No products found matching "$_currentQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Check your spelling or try searching with a different keyword.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _handleNewSearch('');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Browse All Products'),
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
        // Header Result Bar matching SearchPageClient.tsx
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentQuery.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Results for: ',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"$_currentQuery"',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.filter == 'featured'
                                  ? Icons.stars_rounded
                                  : (widget.productType == 'combo'
                                      ? Icons.layers_rounded
                                      : (widget.brand != null
                                          ? Icons.verified_rounded
                                          : Icons.shopping_bag_rounded)),
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.customTitle ??
                                  (widget.filter == 'featured'
                                      ? 'Featured Products'
                                      : (widget.productType == 'combo'
                                          ? 'Combo Packs & Deals'
                                          : (widget.brand != null
                                              ? '${widget.brand} Products'
                                              : 'All Products'))),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      Text(
                        '${state.total} ${state.total == 1 ? "Product" : "Products"} Found',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.total}',
                    style: const TextStyle(
                      fontSize: 12,
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
              crossAxisSpacing: 8, // Exactly 8px horizontal spacing
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

        // Bottom space for BottomAppBar
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

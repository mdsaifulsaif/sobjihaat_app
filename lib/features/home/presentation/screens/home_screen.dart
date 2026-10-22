import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/wishlist_provider.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../../products/presentation/screens/search_screen.dart';
import '../../../products/presentation/screens/wishlist_screen.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../products/presentation/widgets/product_quick_view_modal.dart';
import '../../../subscriptions/data/models/subscription_package_model.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/brand_model.dart';
import '../../data/models/category_model.dart';
import '../providers/home_provider.dart';
import 'categories_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _bannerPageController = PageController();
  final _categoryScrollController = ScrollController();
  int _currentBannerIndex = 0;
  String _selectedSubCategory = 'Household & Cleaning';

  @override
  void dispose() {
    _searchController.dispose();
    _bannerPageController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _scrollCategories(bool forward) {
    if (!_categoryScrollController.hasClients) return;
    final target = forward
        ? _categoryScrollController.offset + 160
        : _categoryScrollController.offset - 160;
    _categoryScrollController.animateTo(
      target.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildAppDrawer(context, homeAsync),
      // Top Fixed Header - Exact match to sobjihaat-frontend MinHeader.tsx
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            left: 14,
            right: 14,
            bottom: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Row 1: Hamburger Menu, Green "S" logo + Brand Title, Wishlist with badge, Profile
              Row(
                children: [
                  // Hamburger Menu (FiMenu)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF1E293B),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Brand Logo & Name: Green rounded-2xl "S" + "SobjiHaat"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          text: 'Sobji',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Haat',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Wishlist Heart Outline Icon Button with Badge (FiHeart)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFF334155),
                            size: 24,
                          ),
                          if (wishlistState.wishlistCount > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Center(
                                  child: Text(
                                    '${wishlistState.wishlistCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Profile User Button (FiUser)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showUserMenuBottomSheet(context, authState);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: authState.isAuthenticated && authState.user != null
                            ? Text(
                                authState.user!.firstName.isNotEmpty
                                    ? authState.user!.firstName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF475569),
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Search input field with rounded-3xl pill shape (exact match to MinHeader.tsx!)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 6),
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search products, categories...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (val) {
                            final q = val.trim();
                            if (q.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(initialQuery: q),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    // Clear button (if text entered) OR Green Search Button (if empty)
                    if (_searchController.text.trim().isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchController.clear()),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          final q = _searchController.text.trim();
                          if (q.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(initialQuery: q),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 36,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(Icons.search_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: homeAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Unable to load catalog', style: AppTypography.headlineMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(homeDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final banners = data.banners;
          final categories = data.categories;
          final products = data.featuredProducts;
          final packages = data.subscriptionPackages;

          // Filter by search text if user typed
          final searchQuery = _searchController.text.trim().toLowerCase();

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.refresh(homeDataProvider),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Promotional Hero Banner (Matching Image 1)
                      _buildHeroBanner(banners),

                      const SizedBox(height: 18),

                      // 2. Product Categories Section (Matching Image 1)
                      _buildProductCategoriesSection(categories),

                      const SizedBox(height: 22),

                      // 3. Featured Products Section - 3 cards visible! (Matching Image 2)
                      _buildProductSliderSection(
                        title: 'Featured Products',
                        products: products,
                        cartState: cartState,
                      ),

                      const SizedBox(height: 22),

                      // 4. Ready to Cook Section - 3 cards visible! (Matching Image 2)
                      _buildProductSliderSection(
                        title: 'Ready to Cook',
                        products: _getReadyToCookProducts(products),
                        cartState: cartState,
                      ),

                      const SizedBox(height: 22),

                      // 5. Combo Products Section - 3 cards visible! (Matching Image 3)
                      _buildProductSliderSection(
                        title: 'Combo Products',
                        products: _getComboProducts(products),
                        cartState: cartState,
                      ),

                      const SizedBox(height: 22),

                      // 6. Our Trusted Brands Section (Marquee - 5 cards visible, matching Image 2)
                      _buildTrustedBrandsSection(data.brands),

                      const SizedBox(height: 28),

                      // 7. Curated Subscription Packages (Matching Image 4 & 5)
                      _buildSubscriptionPackagesSection(packages),
                    ],
                  ),
                ),
              ),

              // Live Search Autocomplete Popup if searching
              if (searchQuery.isNotEmpty)
                _buildSearchOverlay(products, searchQuery),
            ],
          );
        },
      ),
    );
  }

  // --- 1. Promotional Banner (Matching Image 1) ---
  Widget _buildHeroBanner(List<BannerModel> banners) {
    final bannerImages = banners.isNotEmpty
        ? banners.map((b) => b.displayImage).toList()
        : [
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=800&q=80',
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      height: 175,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _bannerPageController,
              itemCount: bannerImages.length,
              onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
              itemBuilder: (context, idx) {
                return Image.network(
                  bannerImages[idx],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFEBF5E1),
                    child: const Center(
                      child: Icon(Icons.eco_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
          ),
          // Banner Indicators overlay (Matching Image 1: - . .)
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  bannerImages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentBannerIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentBannerIndex == i ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Product Categories Section with Arrows (Matching Image 1) ---
  Widget _buildProductCategoriesSection(List<CategoryModel> categories) {
    final catList = categories.isNotEmpty
        ? categories
        : [
            CategoryModel(id: 'c1', name: 'ready to cook', slug: 'ready-to-cook', image: '', productCount: 7),
            CategoryModel(id: 'c2', name: 'subscription', slug: 'subscription', image: '', productCount: 1),
            CategoryModel(id: 'c3', name: 'Spices', slug: 'spices', image: '', productCount: 4),
            CategoryModel(id: 'c4', name: 'Cleaning', slug: 'cleaning', image: '', productCount: 0),
          ];

    return Column(
      children: [
        // Section Header with Leaf Icon and "See all >"
        _buildSectionHeader(
          title: 'Product Categories',
          onSeeAll: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
          },
        ),
        const SizedBox(height: 10),

        // Carousel Container with Left/Right floating round arrow buttons (Exact match to Image 1!)
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 112,
              child: ListView.builder(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: catList.length,
                itemBuilder: (context, index) {
                  final cat = catList[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsScreen(category: cat),
                        ),
                      );
                    },
                    child: Container(
                      width: 82,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Square Image Container
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cat.image.isNotEmpty
                                  ? Image.network(
                                      cat.image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Title
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        // Count (Green matching Image 2)
                        Text(
                          '${cat.productCount} Items',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                },
              ),
            ),

            // Left Navigation Button '<'
            Positioned(
              left: 2,
              child: GestureDetector(
                onTap: () => _scrollCategories(false),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
            ),

            // Right Navigation Button '>'
            Positioned(
              right: 2,
              child: GestureDetector(
                onTap: () => _scrollCategories(true),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3, 4, 5. Product Sliders with 3 Cards Visible! (Matching Images 2 & 3) ---
  Widget _buildProductSliderSection({
    required String title,
    required List<ProductModel> products,
    required CartState cartState,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: title,
          onSeeAll: () {
            SnackbarUtils.showInfo(context, 'Viewing all $title products...');
          },
        ),
        const SizedBox(height: 10),

        // Horizontal Slider: Exactly 3 Cards visible at a time!
        SizedBox(
          height: 195,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width so exactly 3 cards fit with padding & spacing
              final cardWidth = (constraints.maxWidth - 28 - (8 * 2)) / 3;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final prod = products[index];
                  return Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 8),
                    child: ProductCard(
                      product: prod,
                      cartQuantity: cartState.getQuantity(prod.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 6. Our Trusted Brands Section (Marquee - 5 cards visible, matching Image 2) ---
  Widget _buildTrustedBrandsSection(List<BrandModel>? apiBrands) {
    // If API brands empty or null, fallback to real brands with Cloudinary logos
    final brands = (apiBrands != null && apiBrands.isNotEmpty)
        ? apiBrands
        : BrandModel.fallbackBrands;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Our Trusted Brands',
          onSeeAll: () => SnackbarUtils.showInfo(context, 'Viewing all brands...'),
        ),
        const SizedBox(height: 8),
        _MarqueeBrandsTrack(brands: brands),
      ],
    );
  }

  // --- 7. Curated Subscription Packages Section (Matching Image 4 & 5) ---
  Widget _buildSubscriptionPackagesSection(List<SubscriptionPackageModel> packages) {
    return Container(
      color: const Color(0xFFFAFCF8),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Green Pill Header: 🔄 AUTO-DELIVERY & SUBSCRIPTIONS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.autorenew_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'AUTO-DELIVERY & SUBSCRIPTIONS',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title: Curated Subscription Packages
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              text: 'Curated Subscription ',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: 'Packages',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pick a box, set your schedule, and relax. Fresh essentials arrive at your door with free delivery, every time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Tabs: [Household & Cleaning 3] [Organic Fruits 1]
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSubTab('Household & Cleaning', 3),
                const SizedBox(width: 8),
                _buildSubTab('Organic Fruits', 1),
                const SizedBox(width: 8),
                _buildSubTab('Fresh Vegetables', 4),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detailed Subscription Box Card (Exact match to Image 4 & 5!)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Top Banner with Overlay Pills & Title
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=800&q=80',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      // Top Left Red Badge: বেসিক
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA4335),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'বেসিক',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      // Top Right Purple Badge: 🔄 Every Month (1x)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C1D95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.repeat_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Every Month (1x)',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom Overlay Title: HOUSEHOLD & CLEANING, বেসিক ফ্যামিলি প্ল্যান
                      Positioned(
                        bottom: 10,
                        left: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'HOUSEHOLD & CLEANING',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'বেসিক ফ্যামিলি প্ল্যান',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Details (Exact match to Image 5!)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Row: ৳950 / month  ৳1000  Save 5%
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '৳950',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            ' / month',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '৳1000',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Save 5%',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'দৈনন্দিন প্রয়োজনের সাশ্রয়ী প্যাকেজ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),

                      const Divider(height: 24, color: Color(0xFFE2E8F0)),

                      // WHAT'S INSIDE Section
                      const Text(
                        'WHAT\'S INSIDE',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Checklist of Items with green tick
                      _buildCheckItem('গোসলের সাবান (৩টি)'),
                      _buildCheckItem('টুথপেস্ট (১টি)'),
                      _buildCheckItem('টুথব্রাশ (২টি)'),
                      _buildCheckItem('টয়লেট টিস্যু (৪ রোল)'),
                      _buildCheckItem('ডিশওয়াশ বার/লিকুইড (১টি)'),
                      _buildCheckItem('কাপড় কাচার ডিটারজেন্ট (১ প্যাকেট)'),
                      _buildCheckItem('হারপিক/টয়লেট ক্লিনার (১টি)'),
                      _buildCheckItem('হ্যান্ডওয়াশ ১টি'),

                      const SizedBox(height: 14),

                      // Free doorstep delivery included pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Free doorstep delivery included',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Subscribe Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          SnackbarUtils.showSuccess(
                            context,
                            'বেসিক ফ্যামিলি প্ল্যান সাবস্ক্রিপশনে যোগ করা হয়েছে!',
                          );
                        },
                        child: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(String title, int count) {
    final isSelected = _selectedSubCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check, size: 11, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers to split products into Ready to cook and Combo
  List<ProductModel> _getReadyToCookProducts(List<ProductModel> all) {
    return all.reversed.toList();
  }

  List<ProductModel> _getComboProducts(List<ProductModel> all) {
    return all.where((p) => p.isOnSale || p.hasDiscount).toList();
  }

  Widget _buildSearchOverlay(List<ProductModel> products, String query) {
    final matches = products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.unitName != null && p.unitName!.toLowerCase().contains(query)) ||
            (p.shortDescription != null && p.shortDescription!.toLowerCase().contains(query)))
        .take(6)
        .toList();

    return Positioned(
      top: 0,
      left: 14,
      right: 14,
      child: Material(
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header matching MinHeader.tsx (SUGGESTIONS | [N] found)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SUGGESTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (matches.isNotEmpty)
                      Text(
                        '${matches.length} found',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),

              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No products found matching "$query"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() => _searchController.clear());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(initialQuery: ''),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Browse all products',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: matches.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    itemBuilder: (context, index) {
                      final p = matches[index];
                      return InkWell(
                        onTap: () {
                          setState(() => _searchController.clear());
                          ProductQuickViewModal.show(context, p);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  p.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.eco_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (p.unitName != null && p.unitName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        p.unitName!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '৳${p.effectivePrice.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (p.hasDiscount)
                                    Text(
                                      '৳${p.regularPrice.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Footer matching MinHeader.tsx ("View all results for...")
              InkWell(
                onTap: () {
                  final q = query.trim();
                  setState(() => _searchController.clear());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(initialQuery: q),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all results for "$query"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mobile Drawer (Exact replica of MobileNav.tsx in sobjihaat-frontend) ---
  Widget _buildAppDrawer(BuildContext context, AsyncValue<HomeData> homeAsync) {
    final wishlistState = ref.watch(wishlistProvider);
    final categories = homeAsync.value?.categories ?? [];

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 24,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header: Menu Title, Have Complaint?, Close Button (matching MobileNav header)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
              child: Row(
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  // Have Complaint? Button
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showComplaintModal(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.report_problem_outlined, size: 17, color: Color(0xFFEA580C)),
                          SizedBox(width: 4),
                          Text(
                            'Have Complaint?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24, color: Color(0xFF475569)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Track Order with Live badge
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showTrackOrderModal(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🚚', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          const Text(
                            'Track Order',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. My Orders
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: const [
                          Text('📦', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Text(
                            'My Orders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 3. My Wishlist with count badge
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Text('❤️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          const Text(
                            'My Wishlist',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const Spacer(),
                          if (wishlistState.wishlistCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${wishlistState.wishlistCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Categories Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'CATEGORIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Category items
                  ...categories.map(
                    (cat) => InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsScreen(category: cat),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                cat.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    cat.name.isNotEmpty ? cat.name[0] : 'C',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- User Profile Bottom Sheet (Matching MinHeader.tsx user menu) ---
  void _showUserMenuBottomSheet(BuildContext context, AuthState authState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        if (!authState.isAuthenticated || authState.user == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to access your account & orders',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          final user = authState.user!;
          return Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Signed in as', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF334155)),
                    title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF334155)),
                    title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                    },
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    title: const Text('Sign Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // --- Complaint Modal (Matching TopHeader.tsx / MobileNav Have Complaint?) ---
  void _showComplaintModal(BuildContext context) {
    final complaintController = TextEditingController();
    final orderIdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem_rounded, color: Color(0xFFEA580C), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Have a Complaint?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Quick Support Helpline:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFC2410C)),
                  ),
                  SizedBox(height: 4),
                  Text('📞 Phone: 01783176838   •   💬 WhatsApp: 01522114096', style: TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: orderIdController,
              decoration: InputDecoration(
                labelText: 'Order ID or Phone Number',
                hintText: 'e.g. #ORD-1234 or 017...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Complaint Description',
                hintText: 'Tell us about the issue...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                SnackbarUtils.showSuccess(context, 'Complaint received! We will contact you shortly.');
              },
              child: const Text('SUBMIT COMPLAINT', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Track Order Modal (Matching MobileNav Track Order) ---
  void _showTrackOrderModal(BuildContext context) {
    final trackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🚚', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Text(
                  'Track Your Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackController,
              decoration: InputDecoration(
                labelText: 'Order Tracking Number or Phone',
                hintText: 'Enter order number or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final id = trackController.text.trim();
                Navigator.of(ctx).pop();
                if (id.isNotEmpty) {
                  SnackbarUtils.showInfo(context, 'Tracking order: $id (Order is in transit)');
                }
              },
              child: const Text('TRACK NOW', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Smooth Continuous Auto-scrolling Marquee for Trusted Brands (Matching Image 2) ---
class _MarqueeBrandsTrack extends StatefulWidget {
  final List<BrandModel> brands;

  const _MarqueeBrandsTrack({required this.brands});

  @override
  State<_MarqueeBrandsTrack> createState() => _MarqueeBrandsTrackState();
}

class _MarqueeBrandsTrackState extends State<_MarqueeBrandsTrack> {
  late final ScrollController _scrollController;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!mounted || !_scrollController.hasClients || _isUserInteracting) return;
      try {
        final position = _scrollController.position;
        if (!position.hasContentDimensions) return;
        final maxExtent = position.maxScrollExtent;
        if (maxExtent <= 0) return;
        final currentOffset = _scrollController.offset;
        if (currentOffset >= maxExtent - 5) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentOffset + 0.75);
        }
      } catch (_) {}
    });
  }


  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Quadruple items to create smooth continuous infinite loop (matching web Trustedbrands.tsx)
    final marqueeList = [
      ...widget.brands,
      ...widget.brands,
      ...widget.brands,
      ...widget.brands,
    ];

    return SizedBox(
      height: 98,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Exactly 5 cards visible across the screen (smaller compact cards!)
          final cardWidth = (constraints.maxWidth - 28 - (6 * 4)) / 4.85;

          return Listener(
            onPointerDown: (_) => setState(() => _isUserInteracting = true),
            onPointerUp: (_) => setState(() => _isUserInteracting = false),
            onPointerCancel: (_) => setState(() => _isUserInteracting = false),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: marqueeList.length,
              itemBuilder: (context, index) {
                final b = marqueeList[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Genuine Brand Logo (matching Image 2)
                      Expanded(
                        child: Center(
                          child: b.logo.isNotEmpty
                              ? Image.network(
                                  b.logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    b.displayName.isNotEmpty ? b.displayName[0] : 'B',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Text(
                                  b.displayName.isNotEmpty ? b.displayName[0] : 'B',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Brand Name (e.g. Colgate, Marks, Godraj)
                      Text(
                        b.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      // Product Count in green (e.g. "View Products", "2 Products", "1 Product")
                      Text(
                        b.countText,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


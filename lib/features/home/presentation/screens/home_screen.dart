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
import '../../../subscriptions/presentation/widgets/subscription_setup_modal.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/brand_model.dart';
import '../../data/models/category_model.dart';
import '../providers/home_provider.dart';
import 'categories_screen.dart';
import '../../../../core/widgets/sobjihaat_drawer.dart';

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
  String? _selectedSubCategory;

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
      drawer: const SobjiHaatDrawer(),
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

  // --- 7. Curated Subscription Packages Section (Dynamically matching Website) ---
  Widget _buildSubscriptionPackagesSection(List<SubscriptionPackageModel> packages) {
    if (packages.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Process dynamic packages & normalize category name matching web
    String getNormalizedCategory(SubscriptionPackageModel p) {
      final cat = p.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        if (cat.toLowerCase() == 'cleaning') return 'Household & Cleaning';
        return cat;
      }
      final bt = p.boxType.toLowerCase();
      if (bt == 'cleaning') return 'Household & Cleaning';
      if (bt == 'vegetable' || bt == 'vegetables') return 'Fresh Vegetables';
      if (bt == 'fruits' || bt == 'fruit') return 'Organic Fruits';
      if (p.boxType.isNotEmpty) {
        return p.boxType.replaceAll('-', ' ').split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
      return 'Curated Box';
    }

    // 2. Distinct categories ordered by admin priority (pinned first, then lowest sortOrder)
    final catMap = <String, ({bool isPinned, int minOrder})>{};
    for (final pkg in packages) {
      final cat = getNormalizedCategory(pkg);
      final isPinned = pkg.isPinnedToHome;
      final order = pkg.sortOrder;
      if (!catMap.containsKey(cat)) {
        catMap[cat] = (isPinned: isPinned, minOrder: order);
      } else {
        final existing = catMap[cat]!;
        catMap[cat] = (
          isPinned: existing.isPinned || isPinned,
          minOrder: order < existing.minOrder ? order : existing.minOrder,
        );
      }
    }

    final availableCategories = catMap.keys.toList()
      ..sort((a, b) {
        final infoA = catMap[a]!;
        final infoB = catMap[b]!;
        if (infoA.isPinned != infoB.isPinned) {
          return infoA.isPinned ? -1 : 1;
        }
        return infoA.minOrder.compareTo(infoB.minOrder);
      });

    if (availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Category Counts
    final categoryCounts = <String, int>{};
    for (final pkg in packages) {
      final cat = getNormalizedCategory(pkg);
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    // Default category selection
    final activeTab = (_selectedSubCategory != null && availableCategories.contains(_selectedSubCategory))
        ? _selectedSubCategory!
        : availableCategories.first;

    // Filter packages based on active category tab, sorted ascending by price
    final displayedPackages = packages
        .where((p) => getNormalizedCategory(p) == activeTab)
        .toList()
      ..sort((a, b) {
        final priceA = a.salePrice ?? (a.subscriptionPrice > 0 ? a.subscriptionPrice : a.regularPrice);
        final priceB = b.salePrice ?? (b.subscriptionPrice > 0 ? b.subscriptionPrice : b.regularPrice);
        return priceA.compareTo(priceB);
      });

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
          const SizedBox(height: 18),

          // Dynamic Category Tabs matching website
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: availableCategories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSubTab(cat, categoryCounts[cat] ?? 0, activeTab == cat),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Empty State or List of Package Cards
          if (displayedPackages.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inbox_outlined, size: 28, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Subscription Boxes Available',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'There are currently no active subscription packages in this category. Please check back soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: displayedPackages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final pkg = displayedPackages[index];
                final pinnedCount = displayedPackages.where((p) => p.isPinnedToHome).length;
                final isFeatured = pinnedCount == 1
                    ? pkg.isPinnedToHome
                    : (index == 1 || (displayedPackages.length < 3 && index == 0));
                return _buildSubscriptionPackageCard(pkg, isFeatured, getNormalizedCategory(pkg));
              },
            ),

          const SizedBox(height: 24),

          // Benefits Strip (Exact match to Website)
          _buildBenefitsStrip(),
        ],
      ),
    );
  }

  Widget _buildSubTab(String title, int count, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSubCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
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

  Widget _buildSubscriptionPackageCard(
    SubscriptionPackageModel pkg,
    bool isFeatured,
    String categoryName,
  ) {
    final effectivePrice = (pkg.salePrice != null && pkg.salePrice! > 0)
        ? pkg.salePrice!
        : (pkg.subscriptionPrice > 0 ? pkg.subscriptionPrice : pkg.regularPrice);

    final discount = pkg.discountPercent > 0
        ? pkg.discountPercent
        : (pkg.regularPrice > effectivePrice
            ? (((pkg.regularPrice - effectivePrice) / pkg.regularPrice) * 100).round()
            : 0);

    final badgeText = pkg.badge?.isNotEmpty == true
        ? pkg.badge!
        : (discount > 0 ? '$discount% OFF' : 'Popular Choice');

    final freqText = pkg.frequencyText?.isNotEmpty == true
        ? pkg.frequencyText!
        : (pkg.frequency.toLowerCase() == 'weekly' ? 'Every Week (1x)' : 'Every Month (1x)');

    final cycle = pkg.frequency.toLowerCase() == 'weekly' ? 'week' : 'month';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isFeatured ? 1.5 : 1.0,
        ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                pkg.thumbnail.isNotEmpty && pkg.thumbnail.startsWith('http')
                    ? Image.network(
                        pkg.thumbnail,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildSubscriptionPlaceholderImage(),
                      )
                    : _buildSubscriptionPlaceholderImage(),
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
                // Top Left Red Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Top Right Frequency Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          freqText,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Overlay Title: CATEGORY & Name
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        pkg.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Most Popular badge if featured
                if (isFeatured) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, size: 11, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Most Popular',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Price Row: ৳950 / month  ৳1000  Save 5%
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '৳${effectivePrice.toInt()}',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      ' / $cycle',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (pkg.regularPrice > effectivePrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '৳${pkg.regularPrice.toInt()}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Save $discount%',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                if (pkg.idealFor?.isNotEmpty == true || pkg.shortDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    pkg.idealFor ?? pkg.shortDescription!,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],

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
                if (pkg.items.isNotEmpty)
                  ...pkg.items.map((it) {
                    final qty = it.quantity?.trim();
                    return _buildCheckItem(qty != null && qty.isNotEmpty ? '${it.itemName} ($qty)' : it.itemName);
                  })
                else if (pkg.shortDescription?.isNotEmpty == true)
                  _buildCheckItem(pkg.shortDescription!)
                else
                  _buildCheckItem('Essential curated items included'),

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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.repeat_rounded, size: 16),
                  label: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  onPressed: () {
                    SubscriptionSetupModal.show(context, pkg);
                  },
                ),

                // Buy once Button
                if (pkg.allowOneTimePurchase) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF64748B)),
                    label: Text(
                      'Buy once · ৳${pkg.regularPrice.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    onPressed: () {
                      final product = ProductModel(
                        id: pkg.id,
                        name: pkg.name,
                        regularPrice: pkg.regularPrice,
                        salePrice: pkg.salePrice ?? pkg.regularPrice,
                        thumbnail: pkg.thumbnail,
                        shortDescription: pkg.shortDescription,
                        categoryName: categoryName,
                      );
                      ref.read(cartNotifierProvider.notifier).addToCart(product, 1);
                      SnackbarUtils.showSuccess(context, '${pkg.name} কার্টে যোগ করা হয়েছে!');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white24),
      ),
    );
  }

  Widget _buildBenefitsStrip() {
    final benefits = [
      (
        icon: Icons.calendar_today_rounded,
        title: 'Automated Schedule',
        text: 'Never worry about reordering essentials. Delivered to your door on time, every cycle.',
      ),
      (
        icon: Icons.local_shipping_outlined,
        title: '100% Free Delivery',
        text: 'Every recurring subscription box ships free to your doorstep, always.',
      ),
      (
        icon: Icons.pause_circle_outline_rounded,
        title: 'Skip or Pause Anytime',
        text: 'Travelling? Pause, skip or modify your delivery schedule in one click.',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...benefits.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            return Column(
              children: [
                if (idx > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(b.icon, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              b.text,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Cancel anytime. No hidden charges, no lock-in.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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


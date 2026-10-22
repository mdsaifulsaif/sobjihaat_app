import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/sobjihaat_header.dart';
import '../../../products/presentation/providers/wishlist_provider.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../data/models/category_model.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onCategorySelected;

  const CategoriesScreen({super.key, this.onCategorySelected});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      ref.read(categoriesNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catState = ref.watch(categoriesNotifierProvider);
    final wishlistState = ref.watch(wishlistProvider);

    final allCategories = catState.categories;
    final filteredCategories = _searchQuery.isEmpty
        ? allCategories
        : allCategories
            .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: SobjiHaatHeader(
          searchController: _searchController,
          onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
          hintText: 'Search categories...',
        ),
      ),
      body: catState.isLoading && allCategories.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(categoriesNotifierProvider.notifier).refresh(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  const SizedBox(height: 4),

                  // Quick Actions (Matching web MobileNav.tsx)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildQuickAction(
                          icon: Icons.local_shipping_outlined,
                          title: 'Track Order',
                          badge: 'Live',
                          badgeColor: AppColors.primary,
                          onTap: () {
                            SnackbarUtils.showInfo(context, 'Tracking active order status...');
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.border),
                        _buildQuickAction(
                          icon: Icons.inventory_2_outlined,
                          title: 'My Orders',
                          onTap: () {
                            SnackbarUtils.showInfo(context, 'Viewing recent orders...');
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.border),
                        _buildQuickAction(
                          icon: Icons.favorite_border_rounded,
                          title: 'My Wishlist',
                          badge: wishlistState.wishlistCount > 0 ? '${wishlistState.wishlistCount}' : null,
                          badgeColor: Colors.red,
                          onTap: () {
                            SnackbarUtils.showInfo(context, 'Wishlist contains ${wishlistState.wishlistCount} items');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categories Header with Total Count and Page info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALL CATEGORIES (${catState.totalCount > 0 ? catState.totalCount : filteredCategories.length})',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (catState.totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Page ${catState.currentPage} of ${catState.totalPages}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Categories Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      return _buildCategoryCard(cat);
                    },
                  ),

                  // Numbered Pagination Controls
                  if (_searchQuery.isEmpty)
                    _buildPaginationBar(catState),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPaginationBar(CategoriesState catState) {
    if (catState.totalPages <= 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Showing all ${catState.totalCount > 0 ? catState.totalCount : catState.categories.length} categories',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    final currentPage = catState.currentPage;
    final totalPages = catState.totalPages;

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              InkWell(
                onTap: currentPage > 1 && !catState.isLoading
                    ? () {
                        ref.read(categoriesNotifierProvider.notifier).goToPage(currentPage - 1);
                        _scrollToTop();
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentPage > 1 ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentPage > 1 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: currentPage > 1 ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Prev',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: currentPage > 1 ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page Number Buttons [ 1 ] [ 2 ] ...
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPages, (index) {
                  final pageNum = index + 1;
                  final isCurrent = pageNum == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: !isCurrent && !catState.isLoading
                          ? () {
                              ref.read(categoriesNotifierProvider.notifier).goToPage(pageNum);
                              _scrollToTop();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? AppColors.primary : const Color(0xFFCBD5E1),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$pageNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isCurrent ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Next Button
              InkWell(
                onTap: currentPage < totalPages && !catState.isLoading
                    ? () {
                        ref.read(categoriesNotifierProvider.notifier).goToPage(currentPage + 1);
                        _scrollToTop();
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentPage < totalPages ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentPage < totalPages ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: currentPage < totalPages ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: currentPage < totalPages ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Bottom Info & Show All toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page $currentPage of $totalPages (${catState.totalCount} Categories)',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            InkWell(
              onTap: () {
                ref.read(categoriesNotifierProvider.notifier).showAll();
                _scrollToTop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildCategoryCard(CategoryModel cat) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(category: cat),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cat.image.isNotEmpty
                      ? Image.network(
                          cat.image,
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
            const SizedBox(height: 8),
            Text(
              cat.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              cat.productCount > 0
                  ? '${cat.productCount} ${cat.productCount == 1 ? "Item" : "Items"}'
                  : 'View Items',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

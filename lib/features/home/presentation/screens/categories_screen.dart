import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sobjihaat_drawer.dart';
import '../../../../core/widgets/sobjihaat_header.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../../products/presentation/screens/search_screen.dart';
import '../../data/models/category_model.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Auto load more data when user scrolls within 250px of bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
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
    final allCategories = catState.categories;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SobjiHaatDrawer(),
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: SobjiHaatHeader(
          searchController: _searchController,
          hintText: 'Search products, categories...',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onSearchSubmitted: (q) {
            final query = q.trim();
            if (query.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(initialQuery: query),
                ),
              );
            }
          },
        ),
      ),
      body: catState.isLoading && allCategories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(categoriesNotifierProvider.notifier).refresh(),
              child: ListView(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Categories Header with Total Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALL CATEGORIES (${catState.totalCount > 0 ? catState.totalCount : allCategories.length})',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Categories 3-column Grid
                  if (allCategories.isEmpty && !catState.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.category_outlined,
                                size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No categories available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final cat = allCategories[index];
                        return _buildCategoryCard(cat);
                      },
                    ),

                  // Auto-load More Spinner at Bottom (no pagination buttons in UI)
                  if (catState.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.eco_rounded,
                                color: AppColors.primary, size: 28),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.eco_rounded,
                              color: AppColors.primary, size: 28),
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

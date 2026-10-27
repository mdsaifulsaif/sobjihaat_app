import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../../core/widgets/sobjihaat_drawer.dart';
import '../../../../core/widgets/sobjihaat_header.dart';
import '../../../products/presentation/screens/search_screen.dart';
import '../../data/models/brand_model.dart';
import '../providers/home_provider.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  final List<BrandModel>? initialBrands;

  const BrandsScreen({super.key, this.initialBrands});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToBrandProducts(BrandModel brand) {
    final brandSlug = brand.slug.isNotEmpty
        ? brand.slug
        : brand.name.toLowerCase().replaceAll(' ', '-');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          customTitle: '${brand.displayName} Products',
          brand: brandSlug,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeDataProvider);
    final apiBrands = widget.initialBrands ?? homeDataAsync.value?.brands;
    final brands = (apiBrands != null && apiBrands.isNotEmpty)
        ? apiBrands
        : BrandModel.fallbackBrands;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const SobjiHaatDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: SobjiHaatHeader(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: buildSobjiHaatFloatingCartButton(context, ref),
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
      body: CustomScrollView(
        slivers: [
          // Banner & Description Header (matching web BrandsPage.tsx)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'AUTHENTIC PARTNERS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total ${brands.length} Brands',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore All Quality Brands',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Browse our verified producer partners for 100% genuine kitchen essentials and daily groceries in Barisal.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Brands Grid
          if (brands.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No brands available',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.76,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final brand = brands[index];
                    return InkWell(
                      onTap: () => _navigateToBrandProducts(brand),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Box
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Center(
                                child: brand.logo.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          brand.logo,
                                          width: 34,
                                          height: 34,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Text(
                                            brand.displayName.isNotEmpty ? brand.displayName[0] : 'B',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        brand.displayName.isNotEmpty ? brand.displayName[0] : 'B',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 7),

                            // Brand Name
                            Text(
                              brand.displayName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Product Count
                            Text(
                              brand.countText,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Mini Browse indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Browse',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF64748B)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: brands.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

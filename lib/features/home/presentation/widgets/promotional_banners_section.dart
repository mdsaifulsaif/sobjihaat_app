import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../products/presentation/screens/category_products_screen.dart';
import '../../../products/presentation/screens/search_screen.dart';
import '../../data/models/category_model.dart';
import '../../data/models/promotional_banner_model.dart';
import '../screens/categories_screen.dart';

class PromotionalBannersSection extends StatelessWidget {
  final List<PromotionalBannerModel> banners;
  final String title;
  final String subtitle;

  const PromotionalBannersSection({
    super.key,
    required this.banners,
    this.title = 'Feature of this week',
    this.subtitle = 'Exclusive deals, seasonal picks & curated essentials',
  });

  void _handleNavigation(BuildContext context, PromotionalBannerModel banner) async {
    // If categorySlug is available
    if (banner.categorySlug != null && banner.categorySlug!.isNotEmpty) {
      final cat = CategoryModel(
        id: banner.categorySlug!,
        name: banner.title ?? banner.categorySlug!.replaceAll('-', ' ').toUpperCase(),
        slug: banner.categorySlug!,
        image: banner.image,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(category: cat),
        ),
      );
      return;
    }

    final link = banner.link?.trim();
    if (link == null || link.isEmpty) return;

    if (link.startsWith('http://') || link.startsWith('https://')) {
      final uri = Uri.tryParse(link);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (link.startsWith('/category/') || link.startsWith('/cat/')) {
      final parts = link.split('/');
      final slug = parts.isNotEmpty ? parts.last : '';
      if (slug.isNotEmpty) {
        final cat = CategoryModel(
          id: slug,
          name: banner.title ?? slug.replaceAll('-', ' ').toUpperCase(),
          slug: slug,
          image: banner.image,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(category: cat),
          ),
        );
      }
      return;
    }

    if (link == '/categories') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
      return;
    }

    if (link == '/shop' || link.startsWith('/search')) {
      String? query;
      if (link.contains('?q=')) {
        query = link.split('?q=').last;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: query ?? ''),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBanners = banners.where((b) => b.isActive).toList();
    if (activeBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Carousel of weekly deal cards
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: activeBanners.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final banner = activeBanners[index];

              return InkWell(
                onTap: () => _handleNavigation(context, banner),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 165,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Card
                      Container(
                        width: 165,
                        height: 155,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                banner.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        size: 32, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                              // Subtle bottom gradient
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.25),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Caption: Title & Subtitle
                      if (banner.title != null || banner.subtitle != null) ...[
                        const SizedBox(height: 8),
                        if (banner.title != null && banner.title!.isNotEmpty)
                          Text(
                            banner.title!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            banner.subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


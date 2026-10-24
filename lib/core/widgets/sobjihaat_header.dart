import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/products/presentation/providers/wishlist_provider.dart';
import '../../features/products/presentation/screens/search_screen.dart';
import 'sobjihaat_bottom_bar.dart';

class SobjiHaatHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final String hintText;
  final bool autofocus;

  const SobjiHaatHeader({
    super.key,
    this.showBackButton = false,
    this.onBackTap,
    this.onMenuTap,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.hintText = 'Search products, categories...',
    this.autofocus = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(118);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final authState = ref.watch(authNotifierProvider);

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Left icon (Back or Menu), Brand Logo, Wishlist, Profile
          Row(
            children: [
              if (showBackButton)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1E293B),
                      size: 18,
                    ),
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
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

              // Brand Logo: Green rounded "S" + "SobjiHaat" (Image 2)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        text: 'Sobji',
                        style: TextStyle(
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
              ),

              const Spacer(),

              // Wishlist Heart Outline Icon Button with Badge
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref.read(bottomNavIndexProvider.notifier).setIndex(2);
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
              const SizedBox(width: 4),

              // Profile User Button
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (authState.isAuthenticated) {
                    ref.read(bottomNavIndexProvider.notifier).setIndex(3);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
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

          // Row 2: Search input field with rounded pill shape (Image 2)
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
                      controller: searchController,
                      autofocus: autofocus,
                      onChanged: onSearchChanged,
                      onSubmitted: (query) {
                        if (onSearchSubmitted != null) {
                          onSearchSubmitted!(query);
                        } else {
                          final q = query.trim();
                          if (q.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(initialQuery: q),
                              ),
                            );
                          }
                        }
                      },
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                // Green Circular Search Icon Button (Image 2)
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    final q = searchController?.text.trim() ?? '';
                    if (onSearchSubmitted != null) {
                      onSearchSubmitted!(q);
                    } else if (q.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(initialQuery: q),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
}

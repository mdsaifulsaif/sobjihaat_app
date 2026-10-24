import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/cart/presentation/widgets/mini_cart_bottom_sheet.dart';
import '../../features/products/presentation/providers/wishlist_provider.dart';

Widget buildSobjiHaatFloatingCartButton(BuildContext context, WidgetRef ref) {
  final cartState = ref.watch(cartNotifierProvider);

  return Container(
    height: 62,
    width: 62,
    margin: const EdgeInsets.only(top: 10),
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            MiniCartBottomSheet.show(context);
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3.5),
            ),
            child: const Center(
              child: Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        // Cart items badge
        if (cartState.totalCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.discountBadge,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Center(
                child: Text(
                  '${cartState.totalCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class BottomNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavNotifier, int>(() {
  return BottomNavNotifier();
});

Widget buildSobjiHaatBottomAppBar(
  BuildContext context,
  WidgetRef ref, {
  required int currentIndex,
  ValueChanged<int>? onTabSelected,
}) {
  final wishlistState = ref.watch(wishlistProvider);

  void handleNav(int index) {
    if (onTabSelected != null) {
      onTabSelected(index);
      return;
    }
    ref.read(bottomNavIndexProvider.notifier).setIndex(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget buildNavItem({
    required int index,
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => handleNav(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? icon : outlineIcon,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    color: Colors.white,
    elevation: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home
          buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            outlineIcon: Icons.home_outlined,
            label: 'Home',
          ),
          // 2. Categories
          buildNavItem(
            index: 1,
            icon: Icons.grid_view_rounded,
            outlineIcon: Icons.grid_view_outlined,
            label: 'Category',
          ),
          // Spacer for Center Floating Cart Button
          const SizedBox(width: 48),
          // 3. Wishlist
          buildNavItem(
            index: 2,
            icon: Icons.favorite_rounded,
            outlineIcon: Icons.favorite_border_rounded,
            label: 'Wishlist',
            badgeCount: wishlistState.wishlistCount,
          ),
          // 4. Profile
          buildNavItem(
            index: 3,
            icon: Icons.person_rounded,
            outlineIcon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}

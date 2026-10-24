import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../products/presentation/screens/wishlist_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      WishlistScreen(onExplore: () => ref.read(bottomNavIndexProvider.notifier).setIndex(0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      // Floating Elevated Cart Button in Center (Image 1)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: buildSobjiHaatFloatingCartButton(context, ref),
      // Bottom Navigation Bar (Image 1)
      bottomNavigationBar: buildSobjiHaatBottomAppBar(
        context,
        ref,
        currentIndex: currentIndex,
        onTabSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}

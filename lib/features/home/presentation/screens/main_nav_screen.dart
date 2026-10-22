import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../products/presentation/screens/wishlist_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _currentIndex = 0;

  void _onCategorySelected(String slug) {
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      CategoriesScreen(onCategorySelected: _onCategorySelected),
      WishlistScreen(onExplore: () => setState(() => _currentIndex = 0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Floating Elevated Cart Button in Center (Image 1)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: buildSobjiHaatFloatingCartButton(context, ref),
      // Bottom Navigation Bar (Image 1)
      bottomNavigationBar: buildSobjiHaatBottomAppBar(
        context,
        ref,
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

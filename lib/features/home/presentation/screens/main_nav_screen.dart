import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/sobjihaat_bottom_bar.dart';
import '../../../../core/widgets/sobjihaat_drawer.dart';
import '../../../../core/widgets/user_auth_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      WishlistScreen(onExplore: () => ref.read(bottomNavIndexProvider.notifier).setIndex(0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const SobjiHaatDrawer(),
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
          if (index == 1) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 3) {
            final authState = ref.read(authNotifierProvider);
            if (!authState.isAuthenticated || authState.user == null) {
              UserAuthBottomSheet.show(context, ref);
            } else {
              ref.read(bottomNavIndexProvider.notifier).setIndex(3);
            }
          } else {
            ref.read(bottomNavIndexProvider.notifier).setIndex(index);
          }
        },
      ),
    );
  }
}

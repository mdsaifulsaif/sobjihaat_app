import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/products/presentation/providers/category_products_provider.dart';
import '../../features/products/presentation/providers/wishlist_provider.dart';
import '../../features/products/presentation/screens/search_screen.dart';
import '../../features/products/presentation/screens/wishlist_screen.dart';
import '../../features/products/presentation/widgets/product_quick_view_modal.dart';

class SobjiHaatHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
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
    this.onProfileTap,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.hintText = 'Search products, categories...',
    this.autofocus = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(118);

  @override
  ConsumerState<SobjiHaatHeader> createState() => _SobjiHaatHeaderState();
}

class _SobjiHaatHeaderState extends ConsumerState<SobjiHaatHeader> {
  late final TextEditingController _internalController;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  bool _isFocused = false;
  bool _isLoadingSuggestions = false;
  List<ProductModel> _suggestedProducts = [];
  int _totalFound = 0;

  TextEditingController get _effectiveController =>
      widget.searchController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();

    _focusNode.addListener(() {
      final hasFocus = _focusNode.hasFocus;
      if (mounted) {
        setState(() {
          _isFocused = hasFocus;
        });
      }
      if (hasFocus && _effectiveController.text.trim().isNotEmpty) {
        _fetchSuggestions(_effectiveController.text.trim());
      } else if (!hasFocus) {
        _removeSuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeSuggestionsOverlay();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    _internalController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(value);
    }

    final query = value.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      _suggestedProducts = [];
      _totalFound = 0;
      _isLoadingSuggestions = false;
      _removeSuggestionsOverlay();
      setState(() {});
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });
    _showSuggestionsOverlay();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final dataSource = ref.read(productRemoteDataSourceProvider);
      final res = await dataSource.searchProducts(
        searchTerm: query,
        limit: 6,
      );

      if (!mounted) return;
      setState(() {
        _suggestedProducts = res.products;
        _totalFound = res.total;
        _isLoadingSuggestions = false;
      });
      _showSuggestionsOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSuggestions = false;
      });
      _showSuggestionsOverlay();
    }
  }

  void _clearSearch() {
    _effectiveController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _suggestedProducts = [];
      _totalFound = 0;
      _isLoadingSuggestions = false;
    });
    _removeSuggestionsOverlay();
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!('');
    }
  }

  void _handleSearchSubmit(String query) {
    _removeSuggestionsOverlay();
    _focusNode.unfocus();
    final q = query.trim();
    if (widget.onSearchSubmitted != null) {
      widget.onSearchSubmitted!(q);
    } else if (q.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: q),
        ),
      );
    }
  }

  void _showSuggestionsOverlay() {
    if (!mounted) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dropdownWidth = screenWidth - 28; // 14px padding on both sides

        return Stack(
          children: [
            // Barrier dismisser on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _focusNode.unfocus();
                  _removeSuggestionsOverlay();
                },
              ),
            ),
            // Floating Suggestions Dropdown (Exact match to website & screenshot)
            Positioned(
              width: dropdownWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 48), // 44px field height + 4px gap
                child: Material(
                  elevation: 14,
                  shadowColor: const Color(0x38000000),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: _buildSuggestionsContent(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsContent() {
    final query = _effectiveController.text.trim();

    if (_isLoadingSuggestions && _suggestedProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Searching products...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoadingSuggestions && _suggestedProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No products found matching "$query"',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _handleSearchSubmit(query),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Browse all products',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
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
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: "SUGGESTIONS" | "X FOUND" (Matching Image)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUGGESTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '$_totalFound FOUND',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        // Suggestions List (Matching Image with Product thumbnail, title, category, price)
        Flexible(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestedProducts.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF8FAFC),
            ),
            itemBuilder: (context, index) {
              final p = _suggestedProducts[index];
              final price = p.salePrice != null && p.salePrice! > 0
                  ? p.salePrice!.toInt()
                  : p.regularPrice.toInt();
              final hasDiscount = p.salePrice != null &&
                  p.salePrice! > 0 &&
                  p.salePrice! < p.regularPrice;

              return InkWell(
                onTap: () {
                  _removeSuggestionsOverlay();
                  _focusNode.unfocus();
                  ProductQuickViewModal.show(context, p);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFF8FAFC),
                          child: p.thumbnail.isNotEmpty
                              ? Image.network(
                                  p.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.eco_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                )
                              : const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name & Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.categoryName?.isNotEmpty == true
                                  ? p.categoryName!
                                  : 'Groceries',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Price (e.g. ৳15 with strike-through ৳20)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '৳$price',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              '৳${p.regularPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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

        // Bottom Footer: "View all X results"
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        InkWell(
          onTap: () => _handleSearchSubmit(query),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFFFBFCFA),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all $_totalFound results',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Row 1: Left icon (Back or Menu), Green "S" logo box, Wishlist, Profile avatar
          Row(
            children: [
              // Hamburger 3-line Menu Button (Exact match to web & user screenshot)
              Builder(
                builder: (btnContext) => InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (widget.onMenuTap != null) {
                      widget.onMenuTap!();
                    } else {
                      Scaffold.maybeOf(btnContext)?.openDrawer();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.centerLeft,
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF1E293B),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Brand Logo: Green rounded "S" Box (Exact match to user screenshot)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
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
              const SizedBox(width: 6),

              // Profile User Avatar Button (Letter "M" or User Icon in grey box - Image 1)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onProfileTap ??
                    () {
                      if (authState.isAuthenticated) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              fontWeight: FontWeight.w900,
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

          // Row 2: Search input field with green border when active and clear button (Image 1)
          CompositedTransformTarget(
            link: _layerLink,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFocused ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: _isFocused ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 6),
                      child: TextField(
                        controller: _effectiveController,
                        focusNode: _focusNode,
                        autofocus: widget.autofocus,
                        onChanged: _onSearchChanged,
                        onSubmitted: _handleSearchSubmit,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
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

                  // Right button: Grey rounded square with X icon when text exists (Image 3)
                  if (_effectiveController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/screens/checkout_screen.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../providers/wishlist_provider.dart';

class ProductQuickViewModal extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductQuickViewModal({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductQuickViewModal(product: product),
    );
  }

  @override
  ConsumerState<ProductQuickViewModal> createState() => _ProductQuickViewModalState();
}

class _ProductQuickViewModalState extends ConsumerState<ProductQuickViewModal> {
  String _activeTab = 'details'; // 'details' or 'reviews'
  String _detailSubTab = 'description'; // 'description', 'specifications', 'origin'
  bool _isDescExpanded = false;

  // Reviews state
  bool _isLoadingReviews = false;
  ProductReviewsResult? _reviewsResult;

  // Review submission state
  int _newReviewRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final dataSource = ReviewRemoteDataSourceImpl(dioClient: dioClient);
      final result = await dataSource.getProductReviews(widget.product.id);
      if (mounted) {
        setState(() {
          _reviewsResult = result;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _submitReview() async {
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) {
      SnackbarUtils.showError(context, 'Please login to submit a review');
      return;
    }
    if (_newReviewRating == 0) {
      SnackbarUtils.showError(context, 'Please select a star rating');
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please write your review comment');
      return;
    }

    setState(() => _isSubmittingReview = true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final dataSource = ReviewRemoteDataSourceImpl(dioClient: dioClient);
      await dataSource.createReview(
        productId: widget.product.id,
        rating: _newReviewRating,
        comment: _reviewController.text.trim(),
      );
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Review submitted successfully!');
        _reviewController.clear();
        setState(() {
          _newReviewRating = 0;
          _isSubmittingReview = false;
        });
        _fetchReviews();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
        SnackbarUtils.showError(context, 'Failed to submit review: $e');
      }
    }
  }

  Future<void> _handleWhatsAppOrder() async {
    const waNumber = ApiConstants.whatsAppSupportNumber;
    final inCartQty = ref.read(cartNotifierProvider).getQuantity(widget.product.id);
    final qty = inCartQty > 0 ? inCartQty : 1;
    final unitPrice = widget.product.effectivePrice.toInt();
    final totalPrice = unitPrice * qty;
    final skuCode = widget.product.sku ?? widget.product.id;

    String msg = "Hello! SobjiHaat, I'm interested in:\n";
    msg += "Product: ${widget.product.name}\n";
    if (widget.product.unitName != null && widget.product.unitName!.isNotEmpty) {
      msg += "Unit: ${widget.product.weightOrVolume ?? ''} ${widget.product.unitName}\n";
    }
    if (qty > 1) {
      msg += "Quantity: $qty\n";
      msg += "Price: ৳$unitPrice × $qty = ৳$totalPrice\n";
    } else {
      msg += "Price: ৳$unitPrice\n";
    }
    msg += "SKU: $skuCode\n";
    msg += "Product URL: https://sobjihaat.com/search?q=${Uri.encodeComponent(widget.product.name)}";

    final uri = Uri.parse('https://wa.me/$waNumber?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        SnackbarUtils.showError(context, 'Could not launch WhatsApp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.isWishlisted(product.id);
    final cartState = ref.watch(cartNotifierProvider);
    final inCartQty = cartState.getQuantity(product.id);
    final inStock = product.stock > 0;

    final totalReviews = _reviewsResult?.total ?? product.numReviews;
    final averageRating = _reviewsResult?.averageRating ?? product.rating;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & Top Action Icons (Heart Wishlist & Close X)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                // Drag handle pill
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Right icons: Wishlist & Close
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        ref.read(wishlistProvider.notifier).toggleWishlist(product);
                        SnackbarUtils.showSuccess(
                          context,
                          isWishlisted ? 'Removed from wishlist' : 'Added to wishlist ❤️',
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Center
                  Container(
                    height: 220,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: product.thumbnail.isNotEmpty
                          ? Image.network(
                              product.thumbnail,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tags: Category (Ready to Cook) & SKU
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (product.categoryName != null && product.categoryName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.categoryName!.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SKU: ${product.sku?.isNotEmpty == true ? product.sku! : product.id.substring(0, product.id.length > 8 ? 8 : product.id.length)}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Rating Row: Stars + "X (X reviews)"
                  Row(
                    children: [
                      _buildStarRow(averageRating),
                      const SizedBox(width: 8),
                      Text(
                        '${averageRating.toStringAsFixed(1)} ($totalReviews reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price Row: ৳3  ৳746  -100% OFF
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '৳${product.effectivePrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.regularPrice > product.effectivePrice) ...[
                        const SizedBox(width: 10),
                        Text(
                          '৳${product.regularPrice.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${product.computedDiscountPercent}% OFF',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Stock status: ✓ In Stock
                  Row(
                    children: [
                      Icon(
                        inStock ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                        size: 16,
                        color: inStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: inStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Action Row: Quantity Selector & Buy Now Button
                  Row(
                    children: [
                      // Quantity Counter
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: inCartQty > 0 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              onPressed: inCartQty > 0
                                  ? () {
                                      if (inCartQty > 1) {
                                        ref.read(cartNotifierProvider.notifier).updateQuantity(product.id, inCartQty - 1);
                                      } else {
                                        ref.read(cartNotifierProvider.notifier).removeFromCart(product.id);
                                      }
                                    }
                                  : null,
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '$inCartQty',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: inStock ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              onPressed: inStock
                                  ? () {
                                      if (inCartQty == 0) {
                                        ref.read(cartNotifierProvider.notifier).addToCart(product, 1);
                                      } else {
                                        ref.read(cartNotifierProvider.notifier).updateQuantity(product.id, inCartQty + 1);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Buy Now Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: inStock
                              ? () {
                                  if (inCartQty == 0) {
                                    ref.read(cartNotifierProvider.notifier).addToCart(product, 1);
                                  }
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                  );
                                }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Buy Now',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.bolt_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Order via WhatsApp Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _handleWhatsAppOrder,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Order via WhatsApp (হোয়াটসঅ্যাপে অর্ডার)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),

                  // Short Description box (if present)
                  if (product.shortDescription != null && product.shortDescription!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Text(
                        product.shortDescription!.trim(),
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Delivery Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Delivery within 40 - 60 minutes in Barisal city',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Metadata Strip
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        if (product.categoryName != null && product.categoryName!.isNotEmpty)
                          RichText(
                            text: TextSpan(
                              text: 'Category: ',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              children: [
                                TextSpan(
                                  text: product.categoryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        RichText(
                          text: TextSpan(
                            text: 'SKU: ',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            children: [
                              TextSpan(
                                text: product.sku?.isNotEmpty == true
                                    ? product.sku!
                                    : product.id.substring(0, product.id.length > 8 ? 8 : product.id.length),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Type: ',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            children: [
                              TextSpan(
                                text: product.productType ?? 'Single',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- 2 Main Tabs: Details | Reviews ---
                  _buildTabsHeader(totalReviews),

                  const SizedBox(height: 16),

                  // Tab Body
                  if (_activeTab == 'details')
                    _buildDetailsTabContent(product)
                  else
                    _buildReviewsTabContent(averageRating, totalReviews),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Header with Details & Reviews tabs ---
  Widget _buildTabsHeader(int totalReviews) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildMainTabButton('details', 'Details'),
          const SizedBox(width: 24),
          _buildMainTabButton('reviews', 'Reviews${totalReviews > 0 ? " ($totalReviews)" : ""}'),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(String id, String label) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- Details Tab Content ---
  Widget _buildDetailsTabContent(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-pills: [Description] [Specifications] [Origin]
        Row(
          children: [
            _buildSubPill('description', 'Description'),
            const SizedBox(width: 8),
            _buildSubPill('specifications', 'Specifications'),
            const SizedBox(width: 8),
            _buildSubPill('origin', 'Origin'),
          ],
        ),

        const SizedBox(height: 16),

        if (_detailSubTab == 'description') ...[
          _buildDescriptionContent(product),
        ] else if (_detailSubTab == 'specifications') ...[
          _buildSpecificationsContent(product),
        ] else ...[
          _buildOriginContent(),
        ],
      ],
    );
  }

  Widget _buildSubPill(String id, String label) {
    final isSelected = _detailSubTab == id;
    return GestureDetector(
      onTap: () => setState(() => _detailSubTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionContent(ProductModel product) {
    final desc = product.description?.trim().isNotEmpty == true
        ? product.description!.trim()
        : (product.shortDescription?.trim().isNotEmpty == true
            ? product.shortDescription!.trim()
            : 'No description available for this product.');

    final isLong = desc.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          desc,
          maxLines: (!_isDescExpanded && isLong) ? 3 : null,
          overflow: (!_isDescExpanded && isLong) ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF475569),
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isDescExpanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isDescExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecificationsContent(ProductModel product) {
    if (product.specifications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No specifications available for this product.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      children: product.specifications.map((spec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                spec.key,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Text(
                spec.value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOriginContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bangladesh',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        SizedBox(height: 4),
        Text(
          'Sourced from trusted local farms in Bangladesh. 100% natural & organic cultivation.',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // --- Reviews Tab Content (Exact match to Screenshot 2!) ---
  Widget _buildReviewsTabContent(double averageRating, int totalReviews) {
    final counts = _reviewsResult?.ratingCounts ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final reviews = _reviewsResult?.reviews ?? [];
    final authState = ref.watch(authNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Rating Score & Breakdown
        Center(
          child: Column(
            children: [
              Text(
                averageRating > 0 ? averageRating.toStringAsFixed(1) : '0',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              _buildStarRow(averageRating, size: 20),
              const SizedBox(height: 4),
              Text(
                '$totalReviews reviews',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Rating breakdown bars: 5★ down to 1★
        ...[5, 4, 3, 2, 1].map((star) {
          final count = counts[star] ?? 0;
          final pct = totalReviews > 0 ? ((count / totalReviews) * 100).round() : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$star ★',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // Reviews List or Empty State
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final r = reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: Text(
                          r.user?.initial ?? 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.user?.fullName.isNotEmpty == true ? r.user!.fullName : 'Verified Customer',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          _buildStarRow(r.rating, size: 12),
                        ],
                      ),
                      const Spacer(),
                      if (r.createdAt != null)
                        Text(
                          '${r.createdAt!.day}/${r.createdAt!.month}/${r.createdAt!.year}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                  if (r.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.comment,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.35),
                    ),
                  ],
                ],
              );
            },
          ),

        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 20),

        // Write a Review Section (Exact match to Screenshot 2!)
        const Text(
          'Write a Review',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 12),

        if (!authState.isAuthenticated)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'login',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    ' to write a review',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Rating',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _newReviewRating = star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        star <= _newReviewRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: star <= _newReviewRating ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
                        size: 30,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Review',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmittingReview ? null : _submitReview,
                  icon: _isSubmittingReview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text(
                    'Submit Review',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStarRow(double rating, {double size = 15}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        if (rating >= starValue) {
          return Icon(Icons.star_rounded, size: size, color: const Color(0xFFFBBF24));
        } else if (rating >= starValue - 0.5) {
          return Icon(Icons.star_half_rounded, size: size, color: const Color(0xFFFBBF24));
        } else {
          return Icon(Icons.star_border_rounded, size: size, color: const Color(0xFFCBD5E1));
        }
      }),
    );
  }
}

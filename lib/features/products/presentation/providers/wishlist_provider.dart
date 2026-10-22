import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';

class WishlistState {
  final List<ProductModel> wishlist;
  final List<ProductModel> recentlyViewed;

  const WishlistState({
    this.wishlist = const [],
    this.recentlyViewed = const [],
  });

  bool isWishlisted(String productId) {
    return wishlist.any((p) => p.id == productId);
  }

  int get wishlistCount => wishlist.length;
  int get recentlyViewedCount => recentlyViewed.length;

  WishlistState copyWith({
    List<ProductModel>? wishlist,
    List<ProductModel>? recentlyViewed,
  }) {
    return WishlistState(
      wishlist: wishlist ?? this.wishlist,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
    );
  }
}

class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() {
    return const WishlistState();
  }

  bool toggleWishlist(ProductModel product) {
    final exists = state.wishlist.any((p) => p.id == product.id);
    if (exists) {
      state = state.copyWith(
        wishlist: state.wishlist.where((p) => p.id != product.id).toList(),
      );
      return false;
    } else {
      state = state.copyWith(
        wishlist: [product, ...state.wishlist],
      );
      return true;
    }
  }

  void removeFromWishlist(String productId) {
    state = state.copyWith(
      wishlist: state.wishlist.where((p) => p.id != productId).toList(),
    );
  }

  void clearWishlist() {
    state = state.copyWith(wishlist: []);
  }

  void addToRecentlyViewed(ProductModel product) {
    final filtered = state.recentlyViewed.where((p) => p.id != product.id).toList();
    // Keep max 20 recently viewed items
    final updated = [product, ...filtered];
    if (updated.length > 20) {
      updated.removeLast();
    }
    state = state.copyWith(recentlyViewed: updated);
  }

  void clearRecentlyViewed() {
    state = state.copyWith(recentlyViewed: []);
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistState>(() {
  return WishlistNotifier();
});

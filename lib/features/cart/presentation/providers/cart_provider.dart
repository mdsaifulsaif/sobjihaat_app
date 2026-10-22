import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/datasources/cart_remote_datasource.dart';
import '../../data/models/coupon_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.effectivePrice * quantity;
}

class CartState {
  final List<CartItem> items;
  final AppliedCouponResult? appliedCoupon;
  final bool isApplyingCoupon;
  final String? couponError;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.isApplyingCoupon = false,
    this.couponError,
  });

  int get totalCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get couponDiscount => appliedCoupon?.discountAmount ?? 0.0;
  double get totalPayable => (subtotal - couponDiscount).clamp(0.0, double.infinity);
  bool get hasCoupon => appliedCoupon != null && couponDiscount > 0;

  bool isInCart(String productId) => items.any((i) => i.product.id == productId);

  int getQuantity(String productId) {
    final item = items.where((i) => i.product.id == productId);
    return item.isNotEmpty ? item.first.quantity : 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    AppliedCouponResult? appliedCoupon,
    bool clearCoupon = false,
    bool? isApplyingCoupon,
    String? couponError,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      couponError: clearError ? null : (couponError ?? this.couponError),
    );
  }
}

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CartRemoteDataSourceImpl(dioClient: dioClient);
});

final cartNotifierProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  CartRemoteDataSource get _dataSource => ref.read(cartRemoteDataSourceProvider);

  void addToCart(ProductModel product, [int quantity = 1]) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex != -1) {
      final updatedList = List<CartItem>.from(state.items);
      final current = updatedList[existingIndex];
      updatedList[existingIndex] = current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updatedList);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }
  }

  void removeFromCart(String productId) {
    final updated = state.items.where((i) => i.product.id != productId).toList();
    if (updated.isEmpty) {
      state = state.copyWith(items: [], clearCoupon: true);
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final updatedList = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedList);
  }

  void clearCart() {
    state = const CartState(items: []);
  }

  Future<bool> applyCoupon(String code, {String? userId}) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      state = state.copyWith(couponError: 'Please enter a coupon code');
      return false;
    }

    if (state.subtotal <= 0) {
      state = state.copyWith(couponError: 'Your cart is empty');
      return false;
    }

    state = state.copyWith(isApplyingCoupon: true, clearError: true);

    try {
      final itemsPayload = state.items.map((item) {
        return {
          'productID': item.product.id,
          'quantity': item.quantity,
          'unitPrice': item.product.regularPrice,
          'salePrice': item.product.effectivePrice,
          'totalPrice': item.totalPrice,
          'category': item.product.categoryName ?? '',
        };
      }).toList();

      final res = await _dataSource.applyCoupon(
        code: cleanCode,
        subtotal: state.subtotal,
        userId: userId,
        items: itemsPayload,
      );

      state = state.copyWith(
        appliedCoupon: res,
        isApplyingCoupon: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isApplyingCoupon: false,
        couponError: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isApplyingCoupon: false,
        couponError: 'Invalid or ineligible coupon code',
      );
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true, clearError: true);
  }
}

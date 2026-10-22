import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobjihaat_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobjihaat_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:sobjihaat_app/features/cart/presentation/widgets/available_coupons_bottom_sheet.dart';
import 'package:sobjihaat_app/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:sobjihaat_app/features/cart/data/models/coupon_model.dart';
import 'package:sobjihaat_app/features/cart/data/models/area_model.dart';
import 'package:sobjihaat_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:sobjihaat_app/features/products/data/models/product_model.dart';

void main() {
  testWidgets('CheckoutScreen renders without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: CheckoutScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Customer Information'), findsOneWidget);
    // Drain pending futures
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('CheckoutScreen renders with items in cart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final product = ProductModel(
      id: 'p1',
      name: 'Gloria Figueroa',
      regularPrice: 997,
      salePrice: 986,
      stock: 10,
      thumbnail: 'https://example.com/test.jpg',
      images: [],
      isFeatured: true,
      isOnSale: false,
    );

    container.read(cartNotifierProvider.notifier).addToCart(product);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CheckoutScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Customer Information'), findsOneWidget);
    expect(find.text('Gloria Figueroa'), findsNothing); // it's inside preview which is closed by default
    expect(find.text('Payment Summary'), findsOneWidget);
    expect(find.text('Total Payable'), findsNWidgets(2)); // in payment summary & sticky bottom bar
  });

  testWidgets('AvailableCouponsBottomSheet renders empty state cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AvailableCouponsBottomSheet(currentSubtotal: 500),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AvailableCouponsBottomSheet renders coupon list with real coupon', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final coupon = CouponModel.fromJson({
      '_id': '6ad83f4c489fa20f7cd7c416',
      'code': 'TTRRRE',
      'name': 'Special Discount',
      'description': 'Save on orders over 100',
      'discountType': 'fixed',
      'discountValue': 10,
      'maxDiscount': 0,
      'minPurchase': 100,
      'startDate': '2026-10-21T00:00:00.000Z',
      'endDate': '2026-10-28T00:00:00.000Z',
      'applicableTo': 'all',
      'specificUsers': [],
      'isActive': true,
    });

    final mockDataSource = _MockCartDataSource([coupon]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cartRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AvailableCouponsBottomSheet(currentSubtotal: 150),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Available Coupons'), findsOneWidget);
    expect(find.text('TTRRRE'), findsOneWidget);
    expect(find.text('৳10 FLAT OFF'), findsOneWidget);
    expect(find.text('Apply Coupon'), findsOneWidget);
  });
}

class _MockCartDataSource implements CartRemoteDataSource {
  final List<CouponModel> coupons;
  _MockCartDataSource(this.coupons);

  @override
  Future<List<CouponModel>> getAvailableCoupons({String? userId}) async => coupons;

  @override
  Future<AppliedCouponResult> applyCoupon({
    required String code,
    required double subtotal,
    String? userId,
    required List<Map<String, dynamic>> items,
  }) async => AppliedCouponResult(code: code, discountAmount: 10);

  @override
  Future<List<AreaModel>> getAreas() async => [];

  @override
  Future<double> getShippingPreview({required String deliveryType, required double subtotal}) async => 60.0;

  @override
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async => {'success': true};
}

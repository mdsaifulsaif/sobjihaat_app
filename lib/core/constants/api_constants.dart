import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Default local backend base URL based on device environment
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 maps to host machine localhost in Android Emulator
      return 'http://10.0.2.2:5001/api/v1';
    }
    // iOS simulator, macOS, or others
    return 'http://localhost:5001/api/v1';
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String getMe = '/auth/get-me';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/update-profile';

  // Store & Catalog Endpoints
  static const String banners = '/banners';
  static const String categories = '/categories';
  static const String products = '/products';
  static String productsByCategory(String slug) => '/products/category/$slug';
  static const String featuredProducts = '/products/featured';
  static const String subscriptionPackages = '/subscription-packages';
  static const String brands = '/brands';
  static const String areas = '/area';

  // Order, Checkout & Coupon Endpoints
  static const String placeOrder = '/order/place-order';
  static const String myOrders = '/order/my-orders';
  static String cancelOrder(String id) => '/order/cancel/$id';
  static String trackOrder(String id) => '/order/track/$id';
  static const String shippingPreview = '/shipping/preview';
  static const String availableCoupons = '/coupons/available';
  static const String applyCoupon = '/coupons/apply';

  // WhatsApp Support
  static const String whatsAppSupportNumber = '8801604321819';
  static const String whatsAppSupportUrl = 'https://wa.me/8801604321819';

  // Complaint & Feedback
  static const String complaints = '/complaints';

  // Reviews Endpoints
  static const String addReview = '/reviews/add-review';
  static String productReviews(String productId) => '/reviews/$productId';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

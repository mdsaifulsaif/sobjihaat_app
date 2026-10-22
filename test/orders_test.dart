import 'package:flutter_test/flutter_test.dart';
import 'package:sobjihaat_app/features/orders/data/models/order_model.dart';

void main() {
  group('OrderModel Tests', () {
    test('Parses order json correctly and checks properties', () {
      final json = {
        '_id': 'order_123',
        'orderNumber': 'ORD-2026-000001',
        'userID': 'user_abc',
        'items': [
          {
            'productID': 'prod_1',
            'productName': 'Fresh Tomato',
            'thumbnail': 'https://example.com/tomato.jpg',
            'quantity': 2,
            'unitPrice': 50.0,
            'salePrice': 45.0,
            'totalPrice': 90.0,
          },
          {
            'productID': 'prod_2',
            'productName': 'Green Chili',
            'thumbnail': 'https://example.com/chili.jpg',
            'quantity': 1,
            'unitPrice': 20.0,
            'salePrice': 20.0,
            'totalPrice': 20.0,
          }
        ],
        'subtotal': 110.0,
        'discountAmount': 10.0,
        'couponDiscount': 0.0,
        'shippingCharge': 30.0,
        'totalAmount': 130.0,
        'deliveryType': 'local',
        'deliveryAddress': {
          'name': 'Saiful Islam',
          'phone': '01727841588',
          'area': {'name': 'College Road'},
          'houseNo': '12',
          'road': '4',
        },
        'paymentMethod': 'cod',
        'paymentStatus': 'unpaid',
        'status': 'pending',
        'createdAt': '2026-10-22T12:00:00.000Z',
        'updatedAt': '2026-10-22T12:00:00.000Z',
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'order_123');
      expect(order.orderNumber, 'ORD-2026-000001');
      expect(order.items.length, 2);
      expect(order.totalItemCount, 3);
      expect(order.canCancel, true);
      expect(order.formattedStatus, 'Pending');
      expect(order.paymentMethodDisplay, 'Cash on Delivery');
      expect(order.deliveryAddress?.areaName, 'College Road');
      expect(order.deliveryAddress?.fullAddress, 'House 12, Road 4, College Road');
    });

    test('canCancel returns false for delivered or cancelled orders', () {
      final jsonDelivered = {
        '_id': 'order_delivered',
        'orderNumber': 'ORD-2026-000002',
        'userID': 'user_abc',
        'items': [],
        'subtotal': 100.0,
        'discountAmount': 0.0,
        'couponDiscount': 0.0,
        'shippingCharge': 0.0,
        'totalAmount': 100.0,
        'deliveryType': 'local',
        'paymentMethod': 'cod',
        'paymentStatus': 'paid',
        'status': 'delivered',
        'createdAt': '2026-10-22T12:00:00.000Z',
        'updatedAt': '2026-10-22T12:00:00.000Z',
      };

      final order = OrderModel.fromJson(jsonDelivered);
      expect(order.canCancel, false);
      expect(order.formattedStatus, 'Delivered');
    });
  });
}

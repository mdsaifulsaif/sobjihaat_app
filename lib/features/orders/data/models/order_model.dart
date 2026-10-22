class OrderItemModel {
  final String productId;
  final String productName;
  final String thumbnail;
  final String? sku;
  final int quantity;
  final String? unit;
  final double? weightOrVolume;
  final double unitPrice;
  final double salePrice;
  final double totalPrice;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.thumbnail,
    this.sku,
    required this.quantity,
    this.unit,
    this.weightOrVolume,
    required this.unitPrice,
    required this.salePrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    String prodId = '';
    if (json['productID'] is Map) {
      prodId = json['productID']['_id']?.toString() ?? '';
    } else if (json['productID'] != null) {
      prodId = json['productID'].toString();
    }

    return OrderItemModel(
      productId: prodId,
      productName: json['productName']?.toString() ?? 'Grocery Item',
      thumbnail: json['thumbnail']?.toString() ?? '',
      sku: json['sku']?.toString(),
      quantity: parseInt(json['quantity']),
      unit: json['unit']?.toString(),
      weightOrVolume: json['weightOrVolume'] != null ? parseDouble(json['weightOrVolume']) : null,
      unitPrice: parseDouble(json['unitPrice']),
      salePrice: parseDouble(json['salePrice']),
      totalPrice: parseDouble(json['totalPrice']),
    );
  }
}

class OrderAddressModel {
  final String name;
  final String phone;
  final String? areaName;
  final String? areaId;
  final String? district;
  final String? upazila;
  final String? houseNo;
  final String? road;
  final String? flatNo;
  final String? deliveryNotes;
  final String? label;

  OrderAddressModel({
    required this.name,
    required this.phone,
    this.areaName,
    this.areaId,
    this.district,
    this.upazila,
    this.houseNo,
    this.road,
    this.flatNo,
    this.deliveryNotes,
    this.label,
  });

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    String? aName;
    String? aId;

    if (json['area'] is Map) {
      aName = json['area']['name']?.toString();
      aId = json['area']['_id']?.toString();
    } else if (json['area'] != null) {
      aId = json['area'].toString();
    }

    return OrderAddressModel(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      areaName: aName,
      areaId: aId,
      district: json['district']?.toString(),
      upazila: json['upazila']?.toString(),
      houseNo: json['houseNo']?.toString(),
      road: json['road']?.toString(),
      flatNo: json['flatNo']?.toString(),
      deliveryNotes: json['deliveryNotes']?.toString(),
      label: json['label']?.toString(),
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (flatNo != null && flatNo!.isNotEmpty) parts.add('Flat $flatNo');
    if (houseNo != null && houseNo!.isNotEmpty) parts.add('House $houseNo');
    if (road != null && road!.isNotEmpty) parts.add('Road $road');
    if (areaName != null && areaName!.isNotEmpty) parts.add(areaName!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    return parts.isEmpty ? 'Address not specified' : parts.join(', ');
  }
}

class OrderTimelineModel {
  final String status;
  final DateTime? changedAt;
  final String? note;

  OrderTimelineModel({
    required this.status,
    this.changedAt,
    this.note,
  });

  factory OrderTimelineModel.fromJson(Map<String, dynamic> json) {
    return OrderTimelineModel(
      status: json['status']?.toString() ?? '',
      changedAt: json['changedAt'] != null ? DateTime.tryParse(json['changedAt'].toString()) : null,
      note: json['note']?.toString(),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double couponDiscount;
  final double shippingCharge;
  final double totalAmount;
  final String deliveryType;
  final OrderAddressModel? deliveryAddress;
  final DateTime? estimatedDelivery;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? cancelReason;
  final String? specialInstructions;
  final List<OrderTimelineModel> statusTimeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.couponDiscount,
    required this.shippingCharge,
    required this.totalAmount,
    required this.deliveryType,
    this.deliveryAddress,
    this.estimatedDelivery,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.cancelReason,
    this.specialInstructions,
    this.statusTimeline = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final rawItems = json['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => OrderItemModel.fromJson(i))
          .toList();
    }

    final rawTimeline = json['statusTimeline'];
    List<OrderTimelineModel> parsedTimeline = [];
    if (rawTimeline is List) {
      parsedTimeline = rawTimeline
          .whereType<Map<String, dynamic>>()
          .map((t) => OrderTimelineModel.fromJson(t))
          .toList();
    }

    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      userId: json['userID']?.toString() ?? '',
      items: parsedItems,
      subtotal: parseDouble(json['subtotal']),
      discountAmount: parseDouble(json['discountAmount']),
      couponDiscount: parseDouble(json['couponDiscount']),
      shippingCharge: parseDouble(json['shippingCharge']),
      totalAmount: parseDouble(json['totalAmount']),
      deliveryType: json['deliveryType']?.toString() ?? 'local',
      deliveryAddress: json['deliveryAddress'] is Map<String, dynamic>
          ? OrderAddressModel.fromJson(json['deliveryAddress'])
          : null,
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'].toString())
          : null,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      status: json['status']?.toString() ?? 'pending',
      cancelReason: json['cancelReason']?.toString(),
      specialInstructions: json['specialInstructions']?.toString(),
      statusTimeline: parsedTimeline,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get canCancel =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed';

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'out_for_delivery':
      case 'out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'sslcommerz':
        return 'Online Payment';
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      default:
        return paymentMethod.toUpperCase();
    }
  }
}

class OrdersResponseModel {
  final List<OrderModel> orders;
  final int total;
  final int page;
  final int limit;

  OrdersResponseModel({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory OrdersResponseModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final rawOrders = json['orders'];
    List<OrderModel> list = [];
    if (rawOrders is List) {
      list = rawOrders
          .whereType<Map<String, dynamic>>()
          .map((o) => OrderModel.fromJson(o))
          .toList();
    }

    return OrdersResponseModel(
      orders: list,
      total: parseInt(json['total']),
      page: parseInt(json['page']),
      limit: parseInt(json['limit']),
    );
  }
}

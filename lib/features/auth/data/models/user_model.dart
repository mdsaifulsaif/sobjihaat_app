class ShippingAddress {
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? area;
  final String? areaId;

  ShippingAddress({
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.area,
    this.areaId,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShippingAddress();
    return ShippingAddress(
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      area: json['area'] as String?,
      areaId: json['areaId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        if (area != null) 'area': area,
        if (areaId != null) 'areaId': areaId,
      };
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phoneNumber;
  final String status;
  final String? avatarUrl;
  final bool isVerified;
  final String authProvider;
  final ShippingAddress? shippingAddress;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'user',
    this.phoneNumber,
    this.status = 'active',
    this.avatarUrl,
    this.isVerified = false,
    this.authProvider = 'local',
    this.shippingAddress,
    this.createdAt,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? extractAvatarUrl(dynamic avatarData) {
      if (avatarData is String) return avatarData;
      if (avatarData is Map<String, dynamic>) {
        return avatarData['url'] as String?;
      }
      return null;
    }

    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      avatarUrl: extractAvatarUrl(json['avatar']),
      isVerified: json['isVerified'] == true,
      authProvider: (json['authProvider'] ?? 'local').toString(),
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'phoneNumber': phoneNumber,
        'status': status,
        'avatar': avatarUrl != null ? {'url': avatarUrl} : null,
        'isVerified': isVerified,
        'authProvider': authProvider,
        'shippingAddress': shippingAddress?.toJson(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? phoneNumber,
    String? status,
    String? avatarUrl,
    bool? isVerified,
    String? authProvider,
    ShippingAddress? shippingAddress,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      authProvider: authProvider ?? this.authProvider,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

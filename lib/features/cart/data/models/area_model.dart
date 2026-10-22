class AreaModel {
  final String id;
  final String name;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final double radius;

  AreaModel({
    required this.id,
    required this.name,
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.radius = 1500,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isActive: json['isActive'] != false,
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      radius: json['radius'] is num ? (json['radius'] as num).toDouble() : 1500,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'isActive': isActive,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      };
}

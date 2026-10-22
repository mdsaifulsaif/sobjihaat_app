class AreaModel {
  final String id;
  final String name;
  final bool isActive;

  AreaModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'isActive': isActive,
      };
}

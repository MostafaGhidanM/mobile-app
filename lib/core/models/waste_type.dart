class WasteType {
  final String id;
  final String nameAr;
  final String nameEn;
  final DateTime createdAt;
  final DateTime updatedAt;

  WasteType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WasteType.fromJson(Map<String, dynamic> json) {
    return WasteType(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}


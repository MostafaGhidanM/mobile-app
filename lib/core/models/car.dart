class CarBrand {
  final String id;
  final String nameAr;
  final String? nameEn;

  CarBrand({
    required this.id,
    required this.nameAr,
    this.nameEn,
  });

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'],
    );
  }
}

class CarType {
  final String id;
  final String nameAr;
  final String? nameEn;

  CarType({
    required this.id,
    required this.nameAr,
    this.nameEn,
  });

  factory CarType.fromJson(Map<String, dynamic> json) {
    return CarType(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'],
    );
  }
}

class Car {
  final String id;
  final String carImage;
  final double maximumCapacity;
  final String carTypeId;
  final String carBrandId;
  final String licenceFrontImage;
  final String licenceBackImage;
  final String carPlate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final CarBrand? carBrand;
  final CarType? carType;

  Car({
    required this.id,
    required this.carImage,
    required this.maximumCapacity,
    required this.carTypeId,
    required this.carBrandId,
    required this.licenceFrontImage,
    required this.licenceBackImage,
    required this.carPlate,
    required this.createdAt,
    required this.updatedAt,
    this.carBrand,
    this.carType,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? '',
      carImage: json['carImage'] ?? '',
      maximumCapacity: (json['maximumCapacity'] ?? 0).toDouble(),
      carTypeId: json['carTypeId'] ?? '',
      carBrandId: json['carBrandId'] ?? '',
      licenceFrontImage: json['licenceFrontImage'] ?? '',
      licenceBackImage: json['licenceBackImage'] ?? '',
      carPlate: json['carPlate'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      carBrand: json['carBrand'] != null ? CarBrand.fromJson(json['carBrand']) : null,
      carType: json['carType'] != null ? CarType.fromJson(json['carType']) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'carImage': carImage,
      'maximumCapacity': maximumCapacity,
      'carTypeId': carTypeId,
      'carBrandId': carBrandId,
      'licenceFrontImage': licenceFrontImage,
      'licenceBackImage': licenceBackImage,
      'carPlate': carPlate,
    };
  }
}


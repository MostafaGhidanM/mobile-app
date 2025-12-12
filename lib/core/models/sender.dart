enum Gender {
  male,
  female,
}

enum SenderType {
  residentialUnit,
  collectionCenter,
  mobileCollection,
  collectionWorker,
}

class Sender {
  final String id;
  final String fullName;
  final String nationalId;
  final String address;
  final String mobileNumber;
  final String nationalIdFront;
  final String nationalIdBack;
  final Gender gender;
  final SenderType senderType;
  final double expectedDailyAmount;
  final bool haveSmartPhone;
  final bool familyCompany;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sender({
    required this.id,
    required this.fullName,
    required this.nationalId,
    required this.address,
    required this.mobileNumber,
    required this.nationalIdFront,
    required this.nationalIdBack,
    required this.gender,
    required this.senderType,
    required this.expectedDailyAmount,
    required this.haveSmartPhone,
    required this.familyCompany,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      nationalId: json['nationalId'] ?? '',
      address: json['address'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      nationalIdFront: json['nationalIdFront'] ?? '',
      nationalIdBack: json['nationalIdBack'] ?? '',
      gender: _parseGender(json['gender']),
      senderType: _parseSenderType(json['senderType']),
      expectedDailyAmount: (json['expectedDailyAmount'] ?? 0).toDouble(),
      haveSmartPhone: json['haveSmartPhone'] ?? false,
      familyCompany: json['familyCompany'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static Gender _parseGender(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'FEMALE':
        return Gender.female;
      default:
        return Gender.male;
    }
  }

  static SenderType _parseSenderType(String? type) {
    switch (type?.toUpperCase()) {
      case 'COLLECTION_CENTER':
        return SenderType.collectionCenter;
      case 'MOBILE_COLLECTION':
        return SenderType.mobileCollection;
      case 'COLLECTION_WORKER':
        return SenderType.collectionWorker;
      default:
        return SenderType.residentialUnit;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'nationalId': nationalId,
      'address': address,
      'mobileNumber': mobileNumber,
      'nationalIdFront': nationalIdFront,
      'nationalIdBack': nationalIdBack,
      'gender': gender.name.toUpperCase(),
      'senderType': senderType.name.toUpperCase().replaceAll('_', '_'),
      'expectedDailyAmount': expectedDailyAmount,
      'haveSmartPhone': haveSmartPhone,
      'familyCompany': familyCompany,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'fullName': fullName,
      'nationalId': nationalId,
      'address': address,
      'mobileNumber': mobileNumber,
      'nationalIdFront': nationalIdFront,
      'nationalIdBack': nationalIdBack,
      'gender': gender.name.toUpperCase(),
      'senderType': _senderTypeToApiString(senderType),
      'expectedDailyAmount': expectedDailyAmount,
      'haveSmartPhone': haveSmartPhone,
      'familyCompany': familyCompany,
    };
  }

  String _senderTypeToApiString(SenderType type) {
    switch (type) {
      case SenderType.residentialUnit:
        return 'RESIDENTIAL_UNIT';
      case SenderType.collectionCenter:
        return 'COLLECTION_CENTER';
      case SenderType.mobileCollection:
        return 'MOBILE_COLLECTION';
      case SenderType.collectionWorker:
        return 'COLLECTION_WORKER';
    }
  }
}


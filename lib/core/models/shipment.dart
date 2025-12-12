enum ShipmentStatus {
  pending,
  approved,
  rejected,
}

class RawMaterialShipmentReceived {
  final String id;
  final String shipmentImage;
  final String wasteTypeId;
  final double weight;
  final String senderId;
  final String recyclingUnitId;
  final String? shipmentNumber;
  final String? receiptImage;
  final ShipmentStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data (populated when fetched with relations)
  final String? senderName;
  final String? wasteTypeName;
  final String? senderMobile;

  RawMaterialShipmentReceived({
    required this.id,
    required this.shipmentImage,
    required this.wasteTypeId,
    required this.weight,
    required this.senderId,
    required this.recyclingUnitId,
    this.shipmentNumber,
    this.receiptImage,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.wasteTypeName,
    this.senderMobile,
  });

  factory RawMaterialShipmentReceived.fromJson(Map<String, dynamic> json) {
    return RawMaterialShipmentReceived(
      id: json['id'] ?? '',
      shipmentImage: json['shipmentImage'] ?? '',
      wasteTypeId: json['wasteTypeId'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      senderId: json['senderId'] ?? '',
      recyclingUnitId: json['recyclingUnitId'] ?? '',
      shipmentNumber: json['shipmentNumber'],
      receiptImage: json['receiptImage'],
      status: _parseStatus(json['status']),
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      senderName: json['sender']?['fullName'],
      wasteTypeName: json['wasteType']?['nameAr'] ?? json['wasteType']?['nameEn'],
      senderMobile: json['sender']?['mobileNumber'],
    );
  }

  static ShipmentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return ShipmentStatus.approved;
      case 'REJECTED':
        return ShipmentStatus.rejected;
      default:
        return ShipmentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentImage': shipmentImage,
      'wasteTypeId': wasteTypeId,
      'weight': weight,
      'senderId': senderId,
      'recyclingUnitId': recyclingUnitId,
      'shipmentNumber': shipmentNumber,
      'receiptImage': receiptImage,
      'status': status.name.toUpperCase(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ShipmentListResponse {
  final List<RawMaterialShipmentReceived> items;
  final int total;
  final int page;
  final int pageSize;

  ShipmentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ShipmentListResponse.fromJson(Map<String, dynamic> json) {
    return ShipmentListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => RawMaterialShipmentReceived.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}


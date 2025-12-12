enum ShipmentStatus {
  pending,
  approved,
  rejected,
  sentToFactory,
  receivedAtFactory,
  sentToAdmin,
}

enum ProcessedMaterialShipmentStatus {
  pending,
  sentToFactory,
  receivedAtFactory,
  sentToAdmin,
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

// Processed Material Shipment Model
class ProcessedMaterialShipment {
  final String id;
  final String shipmentNumber;
  final String shipmentImage;
  final String materialTypeId;
  final double weight;
  final String carId;
  final String carPlateNumber;
  final String driverFirstName;
  final String driverSecondName;
  final String driverThirdName;
  final String receiverId;
  final String tradeId;
  final int sentPalletsNumber;
  final DateTime dateOfSending;
  final String? receiptFromPress;
  final ProcessedMaterialShipmentStatus status;
  
  // Step 2 fields (from factory)
  final String? carCheckImage;
  final String? receiptImage;
  final double? receivedWeight;
  final double? emptyCarWeight;
  final double? plenty;
  final String? plentyReason;
  final double? netWeight;
  final String? factoryUnitId;
  
  // Audit fields
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data
  final String? pressUnitName;
  final String? receiverUnitName;
  final String? factoryUnitName;
  final String? materialTypeName;
  final String? tradeName;
  final String? carPlate;

  ProcessedMaterialShipment({
    required this.id,
    required this.shipmentNumber,
    required this.shipmentImage,
    required this.materialTypeId,
    required this.weight,
    required this.carId,
    required this.carPlateNumber,
    required this.driverFirstName,
    required this.driverSecondName,
    required this.driverThirdName,
    required this.receiverId,
    required this.tradeId,
    required this.sentPalletsNumber,
    required this.dateOfSending,
    this.receiptFromPress,
    required this.status,
    this.carCheckImage,
    this.receiptImage,
    this.receivedWeight,
    this.emptyCarWeight,
    this.plenty,
    this.plentyReason,
    this.netWeight,
    this.factoryUnitId,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.pressUnitName,
    this.receiverUnitName,
    this.factoryUnitName,
    this.materialTypeName,
    this.tradeName,
    this.carPlate,
  });

  factory ProcessedMaterialShipment.fromJson(Map<String, dynamic> json) {
    return ProcessedMaterialShipment(
      id: json['id'] ?? '',
      shipmentNumber: json['shipmentNumber'] ?? '',
      shipmentImage: json['shipmentImage'] ?? '',
      materialTypeId: json['materialTypeId'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      carId: json['carId'] ?? '',
      carPlateNumber: json['carPlateNumber'] ?? '',
      driverFirstName: json['driverFirstName'] ?? '',
      driverSecondName: json['driverSecondName'] ?? '',
      driverThirdName: json['driverThirdName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      tradeId: json['tradeId'] ?? '',
      sentPalletsNumber: json['sentPalletsNumber'] ?? 0,
      dateOfSending: DateTime.parse(json['dateOfSending'] ?? DateTime.now().toIso8601String()),
      receiptFromPress: json['receiptFromPress'],
      status: _parseProcessedStatus(json['status']),
      carCheckImage: json['carCheckImage'],
      receiptImage: json['receiptImage'],
      receivedWeight: json['receivedWeight'] != null ? (json['receivedWeight'] as num).toDouble() : null,
      emptyCarWeight: json['emptyCarWeight'] != null ? (json['emptyCarWeight'] as num).toDouble() : null,
      plenty: json['plenty'] != null ? (json['plenty'] as num).toDouble() : null,
      plentyReason: json['plentyReason'],
      netWeight: json['netWeight'] != null ? (json['netWeight'] as num).toDouble() : null,
      factoryUnitId: json['factoryUnitId'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      pressUnitName: json['pressUnit']?['unitName'],
      receiverUnitName: json['receiver']?['unitName'],
      factoryUnitName: json['factoryUnit']?['unitName'],
      materialTypeName: json['materialType']?['nameAr'] ?? json['materialType']?['nameEn'],
      tradeName: json['trade']?['name'],
      carPlate: json['car']?['carPlate'],
    );
  }

  static ProcessedMaterialShipmentStatus _parseProcessedStatus(String? status) {
    if (status == null) return ProcessedMaterialShipmentStatus.pending;
    switch (status.toUpperCase()) {
      case 'SENT_TO_FACTORY':
        return ProcessedMaterialShipmentStatus.sentToFactory;
      case 'RECEIVED_AT_FACTORY':
        return ProcessedMaterialShipmentStatus.receivedAtFactory;
      case 'SENT_TO_ADMIN':
        return ProcessedMaterialShipmentStatus.sentToAdmin;
      case 'APPROVED':
        return ProcessedMaterialShipmentStatus.approved;
      case 'REJECTED':
        return ProcessedMaterialShipmentStatus.rejected;
      default:
        return ProcessedMaterialShipmentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentNumber': shipmentNumber,
      'shipmentImage': shipmentImage,
      'materialTypeId': materialTypeId,
      'weight': weight,
      'carId': carId,
      'carPlateNumber': carPlateNumber,
      'driverFirstName': driverFirstName,
      'driverSecondName': driverSecondName,
      'driverThirdName': driverThirdName,
      'receiverId': receiverId,
      'tradeId': tradeId,
      'sentPalletsNumber': sentPalletsNumber,
      'dateOfSending': dateOfSending.toIso8601String(),
      'receiptFromPress': receiptFromPress,
      'status': _statusToString(status),
      'carCheckImage': carCheckImage,
      'receiptImage': receiptImage,
      'receivedWeight': receivedWeight,
      'emptyCarWeight': emptyCarWeight,
      'plenty': plenty,
      'plentyReason': plentyReason,
      'netWeight': netWeight,
      'factoryUnitId': factoryUnitId,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String _statusToString(ProcessedMaterialShipmentStatus status) {
    switch (status) {
      case ProcessedMaterialShipmentStatus.pending:
        return 'PENDING';
      case ProcessedMaterialShipmentStatus.sentToFactory:
        return 'SENT_TO_FACTORY';
      case ProcessedMaterialShipmentStatus.receivedAtFactory:
        return 'RECEIVED_AT_FACTORY';
      case ProcessedMaterialShipmentStatus.sentToAdmin:
        return 'SENT_TO_ADMIN';
      case ProcessedMaterialShipmentStatus.approved:
        return 'APPROVED';
      case ProcessedMaterialShipmentStatus.rejected:
        return 'REJECTED';
    }
  }
}

class ProcessedMaterialShipmentListResponse {
  final List<ProcessedMaterialShipment> items;
  final int total;
  final int page;
  final int pageSize;

  ProcessedMaterialShipmentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ProcessedMaterialShipmentListResponse.fromJson(Map<String, dynamic> json) {
    return ProcessedMaterialShipmentListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ProcessedMaterialShipment.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}


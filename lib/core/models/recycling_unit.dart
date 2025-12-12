enum RecyclingUnitStatus {
  pending,
  approved,
  rejected,
}

enum UnitType {
  press,
  shredder,
  washingLine,
}

class RecyclingUnit {
  final String id;
  final String unitName;
  final String phoneNumber;
  final String unitOwnerName;
  final String role;
  final RecyclingUnitStatus status;
  final UnitType? unitType;

  RecyclingUnit({
    required this.id,
    required this.unitName,
    required this.phoneNumber,
    required this.unitOwnerName,
    required this.role,
    required this.status,
    this.unitType,
  });

  factory RecyclingUnit.fromJson(Map<String, dynamic> json) {
    return RecyclingUnit(
      id: json['id'] ?? '',
      unitName: json['unitName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      unitOwnerName: json['unitOwnerName'] ?? '',
      role: json['role'] ?? 'RECYCLING_UNIT',
      status: _parseStatus(json['status']),
      unitType: _parseUnitType(json['unitType']),
    );
  }

  static UnitType? _parseUnitType(String? unitType) {
    if (unitType == null) return null;
    switch (unitType.toUpperCase()) {
      case 'PRESS':
        return UnitType.press;
      case 'SHREDDER':
        return UnitType.shredder;
      case 'WASHING_LINE':
        return UnitType.washingLine;
      default:
        return null;
    }
  }

  static RecyclingUnitStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return RecyclingUnitStatus.approved;
      case 'REJECTED':
        return RecyclingUnitStatus.rejected;
      default:
        return RecyclingUnitStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitName': unitName,
      'phoneNumber': phoneNumber,
      'unitOwnerName': unitOwnerName,
      'role': role,
      'status': status.name.toUpperCase(),
      if (unitType != null) 'unitType': _unitTypeToString(unitType!),
    };
  }

  static String _unitTypeToString(UnitType type) {
    switch (type) {
      case UnitType.press:
        return 'PRESS';
      case UnitType.shredder:
        return 'SHREDDER';
      case UnitType.washingLine:
        return 'WASHING_LINE';
    }
  }

  // Helper methods
  bool isPressUnit() => unitType == UnitType.press;
  bool isFactoryUnit() => unitType == UnitType.shredder || unitType == UnitType.washingLine;
  bool isShredder() => unitType == UnitType.shredder;
  bool isWashingLine() => unitType == UnitType.washingLine;
}


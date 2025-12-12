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

  RecyclingUnit({
    required this.id,
    required this.unitName,
    required this.phoneNumber,
    required this.unitOwnerName,
    required this.role,
    required this.status,
  });

  factory RecyclingUnit.fromJson(Map<String, dynamic> json) {
    return RecyclingUnit(
      id: json['id'] ?? '',
      unitName: json['unitName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      unitOwnerName: json['unitOwnerName'] ?? '',
      role: json['role'] ?? 'RECYCLING_UNIT',
      status: _parseStatus(json['status']),
    );
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
    };
  }
}


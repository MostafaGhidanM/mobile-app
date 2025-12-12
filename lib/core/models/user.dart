class User {
  final String id;
  final String fullName;
  final String mobile;
  final String role;
  final int totalPoints;

  User({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.role,
    required this.totalPoints,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? 'USER',
      totalPoints: json['totalPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobile': mobile,
      'role': role,
      'totalPoints': totalPoints,
    };
  }
}


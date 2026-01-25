class Notification {
  final String id;
  final String? userId;
  final String? recyclingUnitId;
  final String title;
  final String message;
  final String type;
  final Map<String, String>? meta;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    this.userId,
    this.recyclingUnitId,
    required this.title,
    required this.message,
    required this.type,
    this.meta,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    Map<String, String>? meta;
    if (json['meta'] != null && json['meta'] is Map) {
      meta = (json['meta'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }
    return Notification(
      id: json['id'] ?? '',
      userId: json['userId'],
      recyclingUnitId: json['recyclingUnitId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      meta: meta,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recyclingUnitId': recyclingUnitId,
      'title': title,
      'message': message,
      'type': type,
      'meta': meta,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? recyclingUnitId,
    String? title,
    String? message,
    String? type,
    Map<String, String>? meta,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recyclingUnitId: recyclingUnitId ?? this.recyclingUnitId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      meta: meta ?? this.meta,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


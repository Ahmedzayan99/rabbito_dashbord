enum NotificationType {
  orderUpdate,
  promotion,
  system,
  payment,
  delivery,
  general,
}

enum NotificationStatus {
  sent,
  delivered,
  read,
  failed,
}

class Notification {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Notification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.status = NotificationStatus.sent,
    this.data,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NotificationStatus.sent,
      ),
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'status': status.name,
      'data': data,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int,
      userId: map['user_id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => NotificationStatus.sent,
      ),
      data: map['data'] as Map<String, dynamic>?,
      readAt: map['read_at'] != null 
          ? DateTime.parse(map['read_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.status == status &&
        other.data == data &&
        other.readAt == readAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      message,
      type,
      status,
      data,
      readAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, userId: $userId, title: $title, message: $message, type: $type, status: $status, data: $data, readAt: $readAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
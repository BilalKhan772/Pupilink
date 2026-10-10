class AppNotification {
  final String id;
  final String recipientId;
  final String schoolId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final String? relatedType;
  final String? actionRoute;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.schoolId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.relatedType,
    this.actionRoute,
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AppNotification(
      id: id,
      recipientId: map['recipientId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      relatedId: map['relatedId'] as String?,
      relatedType: map['relatedType'] as String?,
      actionRoute: map['actionRoute'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      readAt: _appNotificationDateTime(map['readAt']),
      createdAt: _appNotificationDateTime(map['createdAt']),
      updatedAt: _appNotificationDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'schoolId': schoolId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'actionRoute': actionRoute,
      'isRead': isRead,
      'readAt': readAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isUnread => !isRead;

  AppNotification copyWith({
    String? id,
    String? recipientId,
    String? schoolId,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    String? relatedType,
    String? actionRoute,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      actionRoute: actionRoute ?? this.actionRoute,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _appNotificationDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic timestamp = value;
    final DateTime date = timestamp.toDate() as DateTime;
    return date;
  } catch (_) {
    return null;
  }
}
class AuditLog {
  final String id;
  final String schoolId;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String action;
  final String entityType;
  final String? entityId;
  final String description;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final DateTime? createdAt;

  const AuditLog({
    required this.id,
    required this.schoolId,
    this.userId,
    this.userName,
    this.userRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.description = '',
    this.metadata = const {},
    this.ipAddress,
    this.createdAt,
  });

  factory AuditLog.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AuditLog(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
      userRole: map['userRole'] as String?,
      action: map['action'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String?,
      description: map['description'] as String? ?? '',
      metadata: _auditLogMetadata(map['metadata']),
      ipAddress: map['ipAddress'] as String?,
      createdAt: _auditLogDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'createdAt': createdAt,
    };
  }

  bool get hasUser => userId != null && userId!.isNotEmpty;

  bool get hasEntity =>
      entityId != null && entityId!.isNotEmpty;

  AuditLog copyWith({
    String? id,
    String? schoolId,
    String? userId,
    String? userName,
    String? userRole,
    String? action,
    String? entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

Map<String, dynamic> _auditLogMetadata(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const {};
}

DateTime? _auditLogDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic date = value.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    // Unsupported date value.
  }

  return null;
}
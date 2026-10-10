
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? schoolId;
  final String? photoUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.schoolId,
    this.photoUrl,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return UserProfile(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'parent',
      schoolId: map['schoolId'] as String?,
      photoUrl: map['photoUrl'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: _profileDateTime(map['createdAt']),
      updatedAt: _profileDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'schoolId': schoolId,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? schoolId,
    String? photoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _profileDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  // Firestore Timestamp ko bhi support karta hai.
  try {
    final dynamic result = value.toDate();
    if (result is DateTime) return result;
  } catch (_) {
    // Unsupported date format.
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

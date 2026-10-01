class ParentProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? city;
  final DateTime? createdAt;

  const ParentProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.city,
    this.createdAt,
  });

  factory ParentProfile.fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    return ParentProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'parent',
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'city': city,
      'createdAt': createdAt,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  ParentProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? city,
    DateTime? createdAt,
  }) {
    return ParentProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
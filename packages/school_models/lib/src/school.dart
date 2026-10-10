
class School {
  final String id;
  final String name;
  final String schoolCode;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const School({
    required this.id,
    required this.name,
    required this.schoolCode,
    required this.city,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory School.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return School(
      id: id,
      name: map['name'] as String? ?? '',
      schoolCode: map['schoolCode'] as String? ?? '',
      city: map['city'] as String? ?? '',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      logoUrl: map['logoUrl'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: _schoolDateTime(map['createdAt']),
      updatedAt: _schoolDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'schoolCode': schoolCode,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  School copyWith({
    String? id,
    String? name,
    String? schoolCode,
    String? city,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolCode: schoolCode ?? this.schoolCode,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _schoolDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

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

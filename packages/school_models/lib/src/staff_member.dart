
class StaffMember {
  final String id;
  final String schoolId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? photoUrl;
  final String? employeeNumber;
  final String? designation;
  final String status;
  final DateTime? joiningDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffMember({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
    this.employeeNumber,
    this.designation,
    this.status = 'active',
    this.joiningDate,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffMember.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return StaffMember(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      employeeNumber: map['employeeNumber'] as String?,
      designation: map['designation'] as String?,
      status: map['status'] as String? ?? 'active',
      joiningDate: _staffMemberDate(map['joiningDate']),
      createdAt: _staffMemberDate(map['createdAt']),
      updatedAt: _staffMemberDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'employeeNumber': employeeNumber,
      'designation': designation,
      'status': status,
      'joiningDate': joiningDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isActive => status == 'active';

  StaffMember copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? photoUrl,
    String? employeeNumber,
    String? designation,
    String? status,
    DateTime? joiningDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      designation: designation ?? this.designation,
      status: status ?? this.status,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _staffMemberDate(dynamic value) {
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

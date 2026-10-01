class ParentChildLink {
  final String id;
  final String parentId;
  final String studentId;
  final String admissionNumber;
  final String city;
  final String schoolId;
  final String schoolName;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const ParentChildLink({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.admissionNumber,
    required this.city,
    required this.schoolId,
    required this.schoolName,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.rejectionReason,
  });

  factory ParentChildLink.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ParentChildLink(
      id: id,
      parentId:
          map['parentId'] as String? ?? '',
      studentId:
          map['studentId'] as String? ?? '',
      admissionNumber:
          map['admissionNumber'] as String? ?? '',
      city:
          map['city'] as String? ?? '',
      schoolId:
          map['schoolId'] as String? ?? '',
      schoolName:
          map['schoolName'] as String? ?? '',
      status:
          map['status'] as String? ?? 'pending',
      requestedAt:
          _parseDate(map['requestedAt']),
      approvedAt:
          _parseDate(map['approvedAt']),
      rejectionReason:
          map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'studentId': studentId,
      'admissionNumber': admissionNumber,
      'city': city,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'status': status,
      'requestedAt': requestedAt,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
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

  bool get isPending {
    return status == 'pending';
  }

  bool get isApproved {
    return status == 'approved';
  }

  bool get isRejected {
    return status == 'rejected';
  }

  ParentChildLink copyWith({
    String? id,
    String? parentId,
    String? studentId,
    String? admissionNumber,
    String? city,
    String? schoolId,
    String? schoolName,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return ParentChildLink(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      admissionNumber:
          admissionNumber ?? this.admissionNumber,
      city: city ?? this.city,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      status: status ?? this.status,
      requestedAt:
          requestedAt ?? this.requestedAt,
      approvedAt:
          approvedAt ?? this.approvedAt,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
    );
  }
}
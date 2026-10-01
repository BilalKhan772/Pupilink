class Student {
  final String id;
  final String name;
  final String admissionNumber;
  final String city;
  final String schoolId;
  final String schoolName;
  final String className;
  final String section;
  final String? photoUrl;
  final bool isActive;

  const Student({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.city,
    required this.schoolId,
    required this.schoolName,
    required this.className,
    required this.section,
    this.photoUrl,
    this.isActive = true,
  });

  factory Student.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Student(
      id: id,
      name: map['name'] as String? ?? '',
      admissionNumber:
          map['admissionNumber'] as String? ?? '',
      city: map['city'] as String? ?? '',
      schoolId:
          map['schoolId'] as String? ?? '',
      schoolName:
          map['schoolName'] as String? ?? '',
      className:
          map['className'] as String? ?? '',
      section:
          map['section'] as String? ?? '',
      photoUrl:
          map['photoUrl'] as String?,
      isActive:
          map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'admissionNumber': admissionNumber,
      'city': city,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'className': className,
      'section': section,
      'photoUrl': photoUrl,
      'isActive': isActive,
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? admissionNumber,
    String? city,
    String? schoolId,
    String? schoolName,
    String? className,
    String? section,
    String? photoUrl,
    bool? isActive,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      admissionNumber:
          admissionNumber ?? this.admissionNumber,
      city: city ?? this.city,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      section: section ?? this.section,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
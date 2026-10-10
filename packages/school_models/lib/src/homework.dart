
class Homework {
  final String id;
  final String schoolId;
  final String classId;
  final String? sectionId;
  final String? subjectId;
  final String title;
  final String description;
  final String? attachmentUrl;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime dueDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Homework({
    required this.id,
    required this.schoolId,
    required this.classId,
    this.sectionId,
    this.subjectId,
    required this.title,
    required this.description,
    this.attachmentUrl,
    required this.assignedBy,
    required this.assignedAt,
    required this.dueDate,
    this.status = 'published',
    this.createdAt,
    this.updatedAt,
  });

  factory Homework.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Homework(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String?,
      subjectId: map['subjectId'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      assignedBy: map['assignedBy'] as String? ?? '',
      assignedAt: _homeworkDate(map['assignedAt']) ??
          DateTime(2000, 1, 1),
      dueDate: _homeworkDate(map['dueDate']) ??
          DateTime(2000, 1, 1),
      status: map['status'] as String? ?? 'published',
      createdAt: _homeworkDate(map['createdAt']),
      updatedAt: _homeworkDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt,
      'dueDate': dueDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isPublished => status == 'published';

  bool get isDraft => status == 'draft';

  bool get isOverdue =>
      isPublished && DateTime.now().isAfter(dueDate);

  Homework copyWith({
    String? id,
    String? schoolId,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? title,
    String? description,
    String? attachmentUrl,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Homework(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _homeworkDate(dynamic value) {
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

enum UserRole {
  superAdmin,
  schoolAdmin,
  classTeacher,
  subjectTeacher,
  monitor,
  parent,
  student,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'superAdmin';
      case UserRole.schoolAdmin:
        return 'schoolAdmin';
      case UserRole.classTeacher:
        return 'classTeacher';
      case UserRole.subjectTeacher:
        return 'subjectTeacher';
      case UserRole.monitor:
        return 'monitor';
      case UserRole.parent:
        return 'parent';
      case UserRole.student:
        return 'student';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.classTeacher:
        return 'Class Teacher';
      case UserRole.subjectTeacher:
        return 'Subject Teacher';
      case UserRole.monitor:
        return 'Monitor';
      case UserRole.parent:
        return 'Parent';
      case UserRole.student:
        return 'Student';
    }
  }
}
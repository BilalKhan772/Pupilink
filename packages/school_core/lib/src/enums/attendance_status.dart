enum AttendanceStatus {
  present,
  absent,
  late,
  leave,
  excused,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.leave:
        return 'leave';
      case AttendanceStatus.excused:
        return 'excused';
    }
  }
}
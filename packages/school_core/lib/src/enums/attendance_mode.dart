enum AttendanceMode {
  manual,
  qrCode,
  biometric,
  automatic,
}

extension AttendanceModeExtension on AttendanceMode {
  String get value {
    switch (this) {
      case AttendanceMode.manual:
        return 'manual';
      case AttendanceMode.qrCode:
        return 'qrCode';
      case AttendanceMode.biometric:
        return 'biometric';
      case AttendanceMode.automatic:
        return 'automatic';
    }
  }
}
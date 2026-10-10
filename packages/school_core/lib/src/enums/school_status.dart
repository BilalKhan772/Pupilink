enum SchoolStatus {
  active,
  inactive,
  suspended,
  pending,
}

extension SchoolStatusExtension on SchoolStatus {
  String get value {
    switch (this) {
      case SchoolStatus.active:
        return 'active';
      case SchoolStatus.inactive:
        return 'inactive';
      case SchoolStatus.suspended:
        return 'suspended';
      case SchoolStatus.pending:
        return 'pending';
    }
  }
}
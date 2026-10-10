enum AccountStatus {
  active,
  inactive,
  suspended,
  pending,
  deleted,
}

extension AccountStatusExtension on AccountStatus {
  String get value {
    switch (this) {
      case AccountStatus.active:
        return 'active';
      case AccountStatus.inactive:
        return 'inactive';
      case AccountStatus.suspended:
        return 'suspended';
      case AccountStatus.pending:
        return 'pending';
      case AccountStatus.deleted:
        return 'deleted';
    }
  }
}
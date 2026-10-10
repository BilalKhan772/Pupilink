enum ChildLinkStatus {
  pending,
  approved,
  rejected,
  revoked,
}

extension ChildLinkStatusExtension on ChildLinkStatus {
  String get value {
    switch (this) {
      case ChildLinkStatus.pending:
        return 'pending';
      case ChildLinkStatus.approved:
        return 'approved';
      case ChildLinkStatus.rejected:
        return 'rejected';
      case ChildLinkStatus.revoked:
        return 'revoked';
    }
  }
}
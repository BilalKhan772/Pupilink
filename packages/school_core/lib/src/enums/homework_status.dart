enum HomeworkStatus {
  draft,
  published,
  closed,
  cancelled,
}

extension HomeworkStatusExtension on HomeworkStatus {
  String get value {
    switch (this) {
      case HomeworkStatus.draft:
        return 'draft';
      case HomeworkStatus.published:
        return 'published';
      case HomeworkStatus.closed:
        return 'closed';
      case HomeworkStatus.cancelled:
        return 'cancelled';
    }
  }
}
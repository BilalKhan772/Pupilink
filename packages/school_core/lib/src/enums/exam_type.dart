enum ExamType {
  monthly,
  midTerm,
  finalTerm,
  annual,
  classTest,
  quiz,
  assignment,
}

extension ExamTypeExtension on ExamType {
  String get value {
    switch (this) {
      case ExamType.monthly:
        return 'monthly';
      case ExamType.midTerm:
        return 'midTerm';
      case ExamType.finalTerm:
        return 'finalTerm';
      case ExamType.annual:
        return 'annual';
      case ExamType.classTest:
        return 'classTest';
      case ExamType.quiz:
        return 'quiz';
      case ExamType.assignment:
        return 'assignment';
    }
  }
}
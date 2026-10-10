class ErrorMessages {
  ErrorMessages._();

  // General
  static const String unknownError =
      'Something went wrong. Please try again.';

  static const String networkError =
      'Please check your internet connection and try again.';

  static const String permissionDenied =
      'You do not have permission to perform this action.';

  static const String operationCancelled =
      'The operation was cancelled.';

  // Authentication
  static const String emailRequired =
      'Email address is required.';

  static const String invalidEmail =
      'Please enter a valid email address.';

  static const String passwordRequired =
      'Password is required.';

  static const String invalidPassword =
      'Password must be at least 6 characters.';

  static const String invalidCredentials =
      'Invalid email or password.';

  static const String accountDisabled =
      'This account has been disabled.';

  static const String accountNotFound =
      'Account not found.';

  // Validation
  static const String nameRequired =
      'Name is required.';

  static const String admissionNumberRequired =
      'Admission number is required.';

  static const String schoolRequired =
      'School is required.';

  static const String classRequired =
      'Class is required.';

  static const String sectionRequired =
      'Section is required.';

  static const String subjectRequired =
      'Subject is required.';
}
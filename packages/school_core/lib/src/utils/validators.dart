import '../constants/error_messages.dart';
import '../constants/regex_patterns.dart';

class Validators {
  Validators._();

  static String? required(
    String? value, {
    String message = 'This field is required.',
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.emailRequired;
    }

    if (!RegexPatterns.email.hasMatch(value.trim())) {
      return ErrorMessages.invalidEmail;
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.passwordRequired;
    }

    if (value.length < 6) {
      return ErrorMessages.invalidPassword;
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.nameRequired;
    }

    if (!RegexPatterns.name.hasMatch(value.trim())) {
      return 'Please enter a valid name.';
    }

    return null;
  }

  static String? admissionNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.admissionNumberRequired;
    }

    if (!RegexPatterns.admissionNumber.hasMatch(value.trim())) {
      return 'Please enter a valid admission number.';
    }

    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    if (!RegexPatterns.phoneNumber.hasMatch(value.trim())) {
      return 'Please enter a valid phone number.';
    }

    return null;
  }

  static String? numeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    if (!RegexPatterns.numeric.hasMatch(value.trim())) {
      return 'Please enter numbers only.';
    }

    return null;
  }

  static String? positiveNumber(String? value) {
    final error = numeric(value);

    if (error != null) {
      return error;
    }

    final number = int.tryParse(value!.trim());

    if (number == null || number <= 0) {
      return 'Please enter a positive number.';
    }

    return null;
  }
}
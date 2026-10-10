
import 'package:cloud_functions/cloud_functions.dart';

class FunctionsErrorMapper {
  const FunctionsErrorMapper();

  String toMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'Please sign in to continue.';
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'not-found':
          return 'The requested information was not found.';
        case 'already-exists':
          return 'This record already exists.';
        case 'invalid-argument':
          return 'Some information is invalid. Please check and try again.';
        case 'failed-precondition':
          return 'This action cannot be completed in the current state.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'unavailable':
          return 'The service is temporarily unavailable.';
        case 'deadline-exceeded':
          return 'The request took too long. Please try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

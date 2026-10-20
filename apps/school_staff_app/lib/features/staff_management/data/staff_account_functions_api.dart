
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final staffAccountFunctionsApiProvider =
    Provider<StaffAccountFunctionsApi>((ref) {
  return StaffAccountFunctionsApi();
});

class StaffAccountFunctionsApi {
  StaffAccountFunctionsApi({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final callable = _functions.httpsCallable('createStaffAccount');

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'Staff account create nahi ho saka.');
    }
  }
}

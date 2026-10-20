
import 'package:cloud_functions/cloud_functions.dart';

class MonitorAccountFunctionsApi {
  MonitorAccountFunctionsApi({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> createMonitorAccount({
    required String name,
    required String email,
    required String password,
    required String sectionId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable('createMonitorAccount');

      final result = await callable.call<Map<String, dynamic>>({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'sectionId': sectionId,
      });

      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        error.message ?? 'Monitor account create nahi ho saka.',
      );
    }
  }
}

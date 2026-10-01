import 'package:cloud_functions/cloud_functions.dart';

class ChildLinkRepository {
  final FirebaseFunctions functions;

  ChildLinkRepository({
    FirebaseFunctions? functions,
  }) : functions =
            functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> linkChild({
    required String city,
    required String schoolId,
    required String admissionNumber,
  }) async {
    final callable =
        functions.httpsCallable('linkChild');

    final result = await callable.call({
      'city': city,
      'schoolId': schoolId,
      'admissionNumber': admissionNumber,
    });

    final data = Map<String, dynamic>.from(
      result.data as Map,
    );

    return data;
  }
}
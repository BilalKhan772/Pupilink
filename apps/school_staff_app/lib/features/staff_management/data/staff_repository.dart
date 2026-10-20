
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'staff_account_functions_api.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(
    firestore: FirebaseFirestore.instance,
    functionsApi: ref.watch(staffAccountFunctionsApiProvider),
  );
});

class StaffRepository {
  StaffRepository({
    required FirebaseFirestore firestore,
    required StaffAccountFunctionsApi functionsApi,
  })  : _firestore = firestore,
        _functionsApi = functionsApi;

  final FirebaseFirestore _firestore;
  final StaffAccountFunctionsApi _functionsApi;

  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _functionsApi.createStaffAccount(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }

  Future<List<Map<String, dynamic>>> getStaff({
    required String schoolId,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw Exception('School ID available nahi hai.');
    }

    final snapshot = await _firestore
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    const staffRoles = {
      'schoolAdmin',
      'classTeacher',
      'subjectTeacher',
      'monitor',
    };

    final staff = snapshot.docs
        .map((doc) => <String, dynamic>{
              'uid': doc.id,
              ...doc.data(),
            })
        .where((item) => staffRoles.contains(item['role']))
        .toList();

    staff.sort(
      (a, b) => (a['name'] as String? ?? '')
          .toLowerCase()
          .compareTo((b['name'] as String? ?? '').toLowerCase()),
    );

    return staff;
  }
}

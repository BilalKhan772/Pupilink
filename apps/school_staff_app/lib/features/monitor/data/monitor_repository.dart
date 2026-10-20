
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monitor_account_functions_api.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return MonitorRepository(
    firestore: FirebaseFirestore.instance,
    functionsApi: MonitorAccountFunctionsApi(),
  );
});

class MonitorRepository {
  MonitorRepository({
    FirebaseFirestore? firestore,
    MonitorAccountFunctionsApi? functionsApi,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functionsApi = functionsApi ?? MonitorAccountFunctionsApi();

  final FirebaseFirestore _firestore;
  final MonitorAccountFunctionsApi _functionsApi;

  Future<List<Map<String, dynamic>>> getSections({
    required String schoolId,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw Exception('School ID available nahi hai.');
    }

    final snapshot = await _firestore
        .collection('sections')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final sections = snapshot.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .where((section) => section['isActive'] != false)
        .toList();

    sections.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return sections;
  }

  Future<List<Map<String, dynamic>>> getMonitors({
    required String schoolId,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw Exception('School ID available nahi hai.');
    }

    final snapshot = await _firestore
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'monitor')
        .get();

    final monitors = snapshot.docs
        .map((doc) => <String, dynamic>{
              'uid': doc.id,
              ...doc.data(),
            })
        .toList();

    monitors.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return monitors;
  }

  Future<Map<String, dynamic>> createMonitor({
    required String name,
    required String email,
    required String password,
    required String sectionId,
  }) {
    return _functionsApi.createMonitorAccount(
      name: name,
      email: email,
      password: password,
      sectionId: sectionId,
    );
  }
}

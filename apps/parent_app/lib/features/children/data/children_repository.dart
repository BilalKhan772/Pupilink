
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildrenRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChildrenRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getMyChildren() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to view your children.');
    }

    final snapshot = await firestore
        .collection('parent_child_links')
        .where('parentId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .get();

    final List<Map<String, dynamic>> children = [];

    for (final linkDoc in snapshot.docs) {
      final linkData = linkDoc.data();
      final studentId = linkData['studentId'] as String? ?? '';

      if (studentId.trim().isEmpty) {
        continue;
      }

      final studentDoc = await firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        continue;
      }

      final studentData = studentDoc.data();

      if (studentData == null) {
        continue;
      }

      children.add({
        ...studentData,
        'linkId': linkDoc.id,
        'studentId': studentDoc.id,
      });
    }

    children.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return children;
  }

  /// Removes only the current parent's connection to a student.
  /// The original student document is never deleted.
  Future<void> removeChildLink({
    required String linkId,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please log in again.');
    }

    if (linkId.trim().isEmpty) {
      throw ArgumentError('Child connection ID is missing.');
    }

    final linkRef = firestore
        .collection('parent_child_links')
        .doc(linkId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(linkRef);

      if (!snapshot.exists) {
        // Treat an already-removed connection as complete.
        return;
      }

      final data = snapshot.data();

      if (data == null || data['parentId'] != user.uid) {
        throw Exception(
          'You are not allowed to remove this child connection.',
        );
      }

      transaction.delete(linkRef);
    });
  }
}

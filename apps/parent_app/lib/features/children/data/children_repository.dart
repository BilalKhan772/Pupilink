import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildrenRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChildrenRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore =
            firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getMyChildren() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception(
        'Parent login nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('parent_child_links')
        .where(
          'parentId',
          isEqualTo: user.uid,
        )
        .where(
          'status',
          isEqualTo: 'approved',
        )
        .get();

    final List<Map<String, dynamic>> children = [];

    for (final linkDoc in snapshot.docs) {
      final linkData = linkDoc.data();

      final studentId =
          linkData['studentId'] as String? ?? '';

      if (studentId.isEmpty) {
        continue;
      }

      final studentDoc = await firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        continue;
      }

      children.add({
        'linkId': linkDoc.id,
        'studentId': studentDoc.id,
        ...studentDoc.data()!,
      });
    }

    return children;
  }
}
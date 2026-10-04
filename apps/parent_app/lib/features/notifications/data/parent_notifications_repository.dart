import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentNotificationsRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ParentNotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore =
            firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception(
        'Parent login nahi hai.',
      );
    }

    final snapshot = await firestore
        .collection('notifications')
        .where(
          'parentId',
          isEqualTo: user.uid,
        )
        .get();

    final notifications =
        snapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).toList();

    notifications.sort((a, b) {
      final createdAtA =
          _getDateTime(a['createdAt']);

      final createdAtB =
          _getDateTime(b['createdAt']);

      return createdAtB.compareTo(
        createdAtA,
      );
    });

    return notifications;
  }

  Future<void> markAsRead({
    required String notificationId,
  }) async {
    if (notificationId.isEmpty) {
      throw Exception(
        'Notification ID available nahi hai.',
      );
    }

    await firestore
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  DateTime _getDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
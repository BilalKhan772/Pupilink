
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../children/data/children_repository.dart';

class ParentNotificationsRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ChildrenRepository childrenRepository;

  ParentNotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChildrenRepository? childrenRepository,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance,
        childrenRepository = childrenRepository ??
            ChildrenRepository(
              firestore: firestore ?? FirebaseFirestore.instance,
              auth: auth ?? FirebaseAuth.instance,
            );

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to view notifications.');
    }

    final snapshot = await firestore
        .collection('notifications')
        .where('parentId', isEqualTo: user.uid)
        .get();

    // Child information is supplementary. If it cannot be loaded,
    // notifications should still remain accessible.
    List<Map<String, dynamic>> children = [];

    try {
      children = await childrenRepository.getMyChildren();
    } catch (_) {
      children = [];
    }

    final notifications = snapshot.docs.map((document) {
      final notification = <String, dynamic>{
        ...document.data(),
        'id': document.id,
      };

      return _enrichNotification(
        notification: notification,
        children: children,
      );
    }).toList();

    notifications.sort((a, b) {
      final createdAtA = _getDateTime(a['createdAt']);
      final createdAtB = _getDateTime(b['createdAt']);

      return createdAtB.compareTo(createdAtA);
    });

    return notifications;
  }

  // ---------------------------------------------------------------------------
  // Add school and child information for the parent-facing UI.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _enrichNotification({
    required Map<String, dynamic> notification,
    required List<Map<String, dynamic>> children,
  }) {
    final nestedData = _asStringMap(notification['data']);

    final schoolId = _firstNonEmpty([
      notification['schoolId'],
      nestedData['schoolId'],
    ]);

    final recipientType = _firstNonEmpty([
      notification['recipientType'],
      nestedData['recipientType'],
    ]).toLowerCase();

    final isSchoolWide =
        recipientType == 'all' ||
        notification['audience'] == 'all';

    final recipientSnapshots = _asMapList(
      notification['recipientChildren'] ??
          nestedData['recipientChildren'],
    );

    final studentIds = <String>{
      ..._stringList(notification['recipientStudentIds']),
      ..._stringList(notification['studentIds']),
      ..._stringList(nestedData['recipientStudentIds']),
      ..._stringList(nestedData['studentIds']),
    };

    final directStudentId = _firstNonEmpty([
      notification['studentId'],
      notification['childId'],
      nestedData['studentId'],
      nestedData['childId'],
    ]);

    if (directStudentId.isNotEmpty) {
      studentIds.add(directStudentId);
    }

    final classIds = <String>{
      ..._stringList(notification['recipientClassIds']),
      ..._stringList(notification['classIds']),
      ..._stringList(nestedData['recipientClassIds']),
      ..._stringList(nestedData['classIds']),
    };

    final directClassId = _firstNonEmpty([
      notification['classId'],
      nestedData['classId'],
    ]);

    if (directClassId.isNotEmpty) {
      classIds.add(directClassId);
    }

    final displayChildren = <Map<String, dynamic>>[];

    // School-wide announcements apply to the complete school.
    // Do not show the same school announcement once for every child.
    if (!isSchoolWide) {
      if (recipientSnapshots.isNotEmpty) {
        // New class-targeted announcements contain recipient snapshots.
        for (final recipient in recipientSnapshots) {
          final studentId = _firstNonEmpty([
            recipient['studentId'],
            recipient['id'],
          ]);

          final currentChild = _findChild(
            children,
            studentId,
          );

          displayChildren.add({
            ...?currentChild,
            ...recipient,
            if (studentId.isNotEmpty) 'studentId': studentId,
          });
        }
      } else if (studentIds.isNotEmpty) {
        // Support older notification documents containing student IDs.
        for (final child in children) {
          final childId = _firstNonEmpty([
            child['studentId'],
            child['id'],
          ]);

          if (studentIds.contains(childId)) {
            displayChildren.add(child);
          }
        }
      } else if (classIds.isNotEmpty) {
        // Support notifications targeted using class IDs.
        for (final child in children) {
          final childClassId = _firstNonEmpty([
            child['classId'],
          ]);

          final childSchoolId = _firstNonEmpty([
            child['schoolId'],
          ]);

          final matchesClass = classIds.contains(childClassId);
          final matchesSchool =
              schoolId.isEmpty || childSchoolId == schoolId;

          if (matchesClass && matchesSchool) {
            displayChildren.add(child);
          }
        }
      } else {
        // Support older notifications with direct child details.
        final studentName = _firstNonEmpty([
          notification['studentName'],
          notification['childName'],
          nestedData['studentName'],
          nestedData['childName'],
        ]);

        if (studentName.isNotEmpty) {
          displayChildren.add({
            'name': studentName,
            'className': _firstNonEmpty([
              notification['className'],
              nestedData['className'],
            ]),
            'section': _firstNonEmpty([
              notification['section'],
              nestedData['section'],
            ]),
          });
        }
      }
    }

    final uniqueChildren = _uniqueChildren(displayChildren);

    // First use the school name already saved in the notification.
    // Otherwise resolve it using the parent's linked child records.
    String schoolName = _firstNonEmpty([
      notification['schoolName'],
      nestedData['schoolName'],
    ]);

    if (schoolName.isEmpty) {
      final matchingSchoolChild = children.cast<Map<String, dynamic>?>().firstWhere(
        (child) {
          if (child == null) return false;

          final childSchoolId = _firstNonEmpty([
            child['schoolId'],
          ]);

          return schoolId.isNotEmpty && childSchoolId == schoolId;
        },
        orElse: () => null,
      );

      if (matchingSchoolChild != null) {
        schoolName = _firstNonEmpty([
          matchingSchoolChild['schoolName'],
        ]);
      }
    }

    if (schoolName.isEmpty && uniqueChildren.isNotEmpty) {
      schoolName = _firstNonEmpty([
        uniqueChildren.first['schoolName'],
      ]);
    }

    String? audienceLabel;

    if (isSchoolWide) {
      audienceLabel = 'All School';
    } else if (recipientType == 'classes') {
      audienceLabel = 'Selected Classes';
    }

    return {
      ...notification,
      '_displaySchoolName': schoolName,
      '_displayChildren': uniqueChildren,
      '_audienceLabel': audienceLabel,
      '_isSchoolWide': isSchoolWide,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is! Map) return {};

    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  Map<String, dynamic>? _findChild(
    List<Map<String, dynamic>> children,
    String studentId,
  ) {
    if (studentId.isEmpty) return null;

    for (final child in children) {
      final childId = _firstNonEmpty([
        child['studentId'],
        child['id'],
      ]);

      if (childId == studentId) {
        return child;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _uniqueChildren(
    List<Map<String, dynamic>> children,
  ) {
    final unique = <String, Map<String, dynamic>>{};

    for (final child in children) {
      final studentId = _firstNonEmpty([
        child['studentId'],
        child['id'],
      ]);

      final name = _firstNonEmpty([
        child['name'],
        child['studentName'],
      ]);

      final key = studentId.isNotEmpty
          ? studentId
          : '$name-${child['className']}-${child['section']}';

      if (key.isNotEmpty && key != '--') {
        unique[key] = child;
      }
    }

    return unique.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Mark notification as read
  // ---------------------------------------------------------------------------

  Future<void> markAsRead({
    required String notificationId,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please log in again.');
    }

    if (notificationId.trim().isEmpty) {
      throw Exception('Notification ID is unavailable.');
    }

    final notificationRef = firestore
        .collection('notifications')
        .doc(notificationId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(notificationRef);

      if (!snapshot.exists) {
        throw Exception('Notification could not be found.');
      }

      final data = snapshot.data();

      if (data == null || data['parentId'] != user.uid) {
        throw Exception(
          'You are not allowed to update this notification.',
        );
      }

      transaction.update(notificationRef, {
        'isRead': true,
      });
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

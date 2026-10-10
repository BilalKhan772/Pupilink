
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDocumentConverter {
  FirestoreDocumentConverter._();

  static Map<String, dynamic>? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    if (!snapshot.exists || data == null) return null;

    return <String, dynamic>{
      ...data,
      'id': snapshot.id,
    };
  }

  static Map<String, dynamic> removeNullValues(
    Map<String, dynamic> data,
  ) {
    return Map<String, dynamic>.fromEntries(
      data.entries.where((entry) => entry.value != null),
    );
  }

  static DateTime? dateTimeFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }

  static Map<String, dynamic> withServerTimestamp(
    Map<String, dynamic> data,
    String field,
  ) {
    return {
      ...data,
      field: FieldValue.serverTimestamp(),
    };
  }
}

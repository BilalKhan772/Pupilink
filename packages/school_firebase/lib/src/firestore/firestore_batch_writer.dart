
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBatchWriter {
  FirestoreBatchWriter({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> write({
    required List<FirestoreBatchOperation> operations,
  }) async {
    if (operations.isEmpty) return;

    // Firestore batches have a maximum of 500 write operations.
    if (operations.length > 500) {
      throw ArgumentError(
        'A Firestore batch cannot exceed 500 operations.',
      );
    }

    final batch = _firestore.batch();

    for (final operation in operations) {
      switch (operation.type) {
        case FirestoreBatchOperationType.set:
          batch.set(
            _firestore.doc(operation.path),
            operation.data!,
            SetOptions(merge: operation.merge),
          );
          break;

        case FirestoreBatchOperationType.update:
          batch.update(
            _firestore.doc(operation.path),
            operation.data!,
          );
          break;

        case FirestoreBatchOperationType.delete:
          batch.delete(
            _firestore.doc(operation.path),
          );
          break;
      }
    }

    await batch.commit();
  }
}

enum FirestoreBatchOperationType {
  set,
  update,
  delete,
}

class FirestoreBatchOperation {
  const FirestoreBatchOperation.set({
    required this.path,
    required this.data,
    this.merge = false,
  })  : type = FirestoreBatchOperationType.set;

  const FirestoreBatchOperation.update({
    required this.path,
    required this.data,
  })  : type = FirestoreBatchOperationType.update,
        merge = false;

  const FirestoreBatchOperation.delete({
    required this.path,
  })  : type = FirestoreBatchOperationType.delete,
        data = null,
        merge = false;

  final String path;
  final FirestoreBatchOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;
}


import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTransactionRunner {
  FirestoreTransactionRunner({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<T> run<T>(
    Future<T> Function(Transaction transaction) action, {
    int maxAttempts = 5,
  }) {
    if (maxAttempts < 1) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Must be at least 1.',
      );
    }

    return _firestore.runTransaction<T>(
      action,
      maxAttempts: maxAttempts,
    );
  }
}

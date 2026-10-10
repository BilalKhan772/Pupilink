
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreClient {
  FirestoreClient({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get instance => _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String path, {
    Source source = Source.serverAndCache,
  }) {
    return document(path).get(GetOptions(source: source));
  }

  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return document(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) {
    return document(path).update(data);
  }

  Future<void> deleteDocument(String path) {
    return document(path).delete();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument(
    String path,
  ) {
    return document(path).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(
    String path,
  ) {
    return collection(path).snapshots();
  }
}

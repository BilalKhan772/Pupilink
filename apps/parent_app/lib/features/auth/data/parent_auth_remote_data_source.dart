import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentAuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ParentAuthRemoteDataSource({
    required this.auth,
    required this.firestore,
  });

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
        await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      throw Exception('Account create nahi ho saka.');
    }

    await firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'role': 'parent',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}
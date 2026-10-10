
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffAuthRemoteDataSource {
  StaffAuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Login unsuccessful. Please try again.');
    }

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!document.exists || document.data() == null) {
      await _auth.signOut();
      throw Exception(
        'Staff profile nahi mila. Administrator se rabta karein.',
      );
    }

    final data = document.data()!;

    final profileEmail = (data['email'] as String? ?? '').trim();

    if (profileEmail.isNotEmpty &&
        profileEmail.toLowerCase() != user.email?.toLowerCase()) {
      await _auth.signOut();
      throw Exception('Staff profile email match nahi karta.');
    }

    final role = data['role'] as String? ?? '';

    const allowedRoles = {
      'schoolAdmin',
      'classTeacher',
      'subjectTeacher',
      'monitor',
    };

    if (!allowedRoles.contains(role)) {
      await _auth.signOut();
      throw Exception(
        'Is account ko School Staff App access ki ijazat nahi hai.',
      );
    }

    final schoolId = data['schoolId'] as String? ?? '';

    if (role != 'superAdmin' && schoolId.trim().isEmpty) {
      await _auth.signOut();
      throw Exception('Staff profile mein schoolId maujood nahi.');
    }

    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': data['name'] as String? ?? 'Staff Member',
      'role': role,
      'schoolId': schoolId,
    };
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

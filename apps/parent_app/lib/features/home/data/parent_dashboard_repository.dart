import 'package:firebase_auth/firebase_auth.dart';

class ParentDashboardRepository {
  final FirebaseAuth auth;

  ParentDashboardRepository({
    required this.auth,
  });

  User? get currentUser {
    return auth.currentUser;
  }

  String get parentEmail {
    return auth.currentUser?.email ?? '';
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}
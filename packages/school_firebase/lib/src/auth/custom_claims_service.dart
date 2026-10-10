
import 'package:firebase_auth/firebase_auth.dart';

class CustomClaimsService {
  CustomClaimsService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> getCurrentUserClaims({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return <String, dynamic>{};
    }

    final tokenResult = await user.getIdTokenResult(forceRefresh);
    final claims = tokenResult.claims;

    if (claims == null) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(claims);
  }

  Future<String?> getRoleClaim({
    String claimName = 'role',
    bool forceRefresh = false,
  }) async {
    final claims = await getCurrentUserClaims(
      forceRefresh: forceRefresh,
    );

    final role = claims[claimName];

    return role is String ? role : null;
  }

  Future<bool> hasClaim(
    String claimName, {
    bool forceRefresh = false,
  }) async {
    final claims = await getCurrentUserClaims(
      forceRefresh: forceRefresh,
    );

    final value = claims[claimName];

    return value == true;
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_messaging_client.dart';

class DeviceTokenService {
  DeviceTokenService({
    FirebaseMessagingClient? messagingClient,
    FirebaseFirestore? firestore,
  })  : _messagingClient =
            messagingClient ?? FirebaseMessagingClient(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessagingClient _messagingClient;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _deviceTokens(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(_validateUid(uid))
        .collection('deviceTokens');
  }

  Future<void> registerCurrentDevice(String uid) async {
    final token = await _messagingClient.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    await saveToken(uid: uid, token: token);
  }

  Future<void> saveToken({
    required String uid,
    required String token,
  }) async {
    final normalizedUid = _validateUid(uid);
    final normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'Device token cannot be empty.',
      );
    }

    await _firestore
        .collection('users')
        .doc(normalizedUid)
        .collection('deviceTokens')
        .doc('current')
        .set({
      'token': normalizedToken,
      'platform': _platformName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentDevice(String uid) async {
    await _deviceTokens(uid).doc('current').delete();
  }

  String get _platformName {
    // Keep platform detection outside this shared package.
    return 'unknown';
  }

  String _validateUid(String uid) {
    final normalized = uid.trim();

    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(uid, 'uid', 'Invalid user ID.');
    }

    return normalized;
  }
}

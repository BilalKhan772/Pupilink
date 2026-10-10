
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseEmulatorConnector {
  FirebaseEmulatorConnector({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> connect({
    required String host,
    int authPort = 9099,
    int firestorePort = 8080,
    int functionsPort = 5001,
    int storagePort = 9199,
    String? functionsRegion,
  }) async {
    if (_connected) return;

    final normalizedHost = host.trim();

    if (normalizedHost.isEmpty) {
      throw ArgumentError.value(
        host,
        'host',
        'Emulator host cannot be empty.',
      );
    }

    _validatePort(authPort, 'authPort');
    _validatePort(firestorePort, 'firestorePort');
    _validatePort(functionsPort, 'functionsPort');
    _validatePort(storagePort, 'storagePort');

    _auth.useAuthEmulator(normalizedHost, authPort);

    _firestore.useFirestoreEmulator(
      normalizedHost,
      firestorePort,
    );

    final region = functionsRegion?.trim();

    final functionsInstance = region == null || region.isEmpty
        ? _functions
        : FirebaseFunctions.instanceFor(region: region);

    functionsInstance.useFunctionsEmulator(
      normalizedHost,
      functionsPort,
    );

    _storage.useStorageEmulator(
      normalizedHost,
      storagePort,
    );

    _connected = true;
  }

  void _validatePort(int port, String name) {
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(
        port,
        name,
        'Port must be between 1 and 65535.',
      );
    }
  }
}

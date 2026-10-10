
import 'package:school_firebase/school_firebase.dart';

import '../config/app_config.dart';

class StaffAppStartup {
  StaffAppStartup._();

  static bool _initialized = false;

  static Future<void> initialize(AppConfig config) async {
    if (_initialized) return;

    if (config.useFirebaseEmulators) {
      final emulatorConnector = FirebaseEmulatorConnector();

      await emulatorConnector.connect(
        host: '127.0.0.1',
        authPort: 9099,
        firestorePort: 8080,
        functionsPort: 5001,
        storagePort: 9199,
      );
    }

    _initialized = true;
  }
}

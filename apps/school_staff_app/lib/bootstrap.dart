
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/school_staff_app.dart';
import 'app/staff_app_startup.dart';
import 'config/app_config.dart';
import 'config/app_flavor.dart';
import 'config/firebase_options.dart';

Future<void> bootstrap({
  required AppFlavor flavor,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.forFlavor(flavor);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await StaffAppStartup.initialize(config);

  runApp(
    ProviderScope(
      child: SchoolStaffApp(config: config),
    ),
  );
}


import 'app_flavor.dart';
import 'environment.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.environment,
    required this.appName,
    required this.useFirebaseEmulators,
  });

  final AppFlavor flavor;
  final AppEnvironment environment;
  final String appName;
  final bool useFirebaseEmulators;

  static AppConfig forFlavor(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.development:
        return const AppConfig(
          flavor: AppFlavor.development,
          environment: AppEnvironment.development,
          appName: 'Pupilink Staff (Development)',
          useFirebaseEmulators: true,
        );

      case AppFlavor.staging:
        return const AppConfig(
          flavor: AppFlavor.staging,
          environment: AppEnvironment.staging,
          appName: 'Pupilink Staff (Staging)',
          useFirebaseEmulators: false,
        );

      case AppFlavor.production:
        return const AppConfig(
          flavor: AppFlavor.production,
          environment: AppEnvironment.production,
          appName: 'Pupilink Staff',
          useFirebaseEmulators: false,
        );
    }
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}

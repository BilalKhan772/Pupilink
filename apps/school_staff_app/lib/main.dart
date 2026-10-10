
import 'bootstrap.dart';
import 'config/app_flavor.dart';

Future<void> main() async {
  await bootstrap(flavor: AppFlavor.development);
}

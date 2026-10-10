
import 'package:flutter_test/flutter_test.dart';
import 'package:school_staff_app/app/school_staff_app.dart';
import 'package:school_staff_app/config/app_config.dart';
import 'package:school_staff_app/config/app_flavor.dart';

void main() {
  testWidgets('School Staff app displays startup screen', (
    WidgetTester tester,
  ) async {
    final config = AppConfig.forFlavor(AppFlavor.development);

    await tester.pumpWidget(
      SchoolStaffApp(config: config),
    );

    expect(find.text('Pupilink School Staff'), findsOneWidget);
    expect(find.text('School management made simple.'), findsOneWidget);
    expect(find.text('Preparing your workspace...'), findsOneWidget);
  });
}

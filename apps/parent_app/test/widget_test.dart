import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parent_app/app/parent_app.dart';

void main() {
  testWidgets(
    'Parent app starts with splash screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ParentApp(),
      );

      expect(
        find.text('School Progress'),
        findsOneWidget,
      );

      expect(
        find.byType(
          CircularProgressIndicator,
        ),
        findsOneWidget,
      );
    },
  );
}
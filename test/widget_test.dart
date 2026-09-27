// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skill_finder/main.dart';

import 'package:provider/provider.dart';

void main() {
  testWidgets('SkillFinder app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const MyApp(),
      ),
    );

    // Verify that login screen is displayed.
    expect(find.text('適性診断 - ログイン'), findsOneWidget);
    expect(find.text('利用者'), findsOneWidget);
    expect(find.text('管理者'), findsOneWidget);
  });
}

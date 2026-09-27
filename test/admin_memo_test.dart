import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_finder/admin_screen.dart';

void main() {
  testWidgets('AdminSkillMemosScreen opens from Tab 2 and handles back', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Tab 2 (分析・職員用メモ)
    final tab2Finder = find.text('分析\n職員用メモ');
    expect(tab2Finder, findsOneWidget);
    await tester.tap(tab2Finder);
    await tester.pumpAndSettle();

    // 2. Find and tap 適性メモ表示 button
    final memoBtnFinder = find.widgetWithText(ElevatedButton, '適性メモ表示');
    expect(memoBtnFinder, findsOneWidget);
    await tester.tap(memoBtnFinder);
    await tester.pumpAndSettle();

    // 3. Verify AdminSkillMemosScreen content
    expect(find.text('【管理】適性メモ (閲覧/代理記録)'), findsOneWidget);
    expect(find.text('新規適性メモ作成'), findsOneWidget);

    // 4. Test saving a memo
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveBtnFinder = find.widgetWithText(ElevatedButton, 'メモを保存');
    expect(saveBtnFinder, findsOneWidget);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    // 5. Verify Back navigation
    await tester.drag(find.byType(ListView).last, const Offset(0, 500));
    await tester.pumpAndSettle();
    final backBtnFinder = find.byTooltip('戻る').last;
    await tester.tap(backBtnFinder);
    await tester.pumpAndSettle();

    // 6. Verify returned to Tab 2 list
    expect(find.text('【管理】適性メモ (閲覧/代理記録)'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '適性メモ表示'), findsOneWidget);
  });
}

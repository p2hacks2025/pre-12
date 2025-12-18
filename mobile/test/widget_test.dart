// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:p2hacks_onyx/app.dart';

void main() {
  testWidgets('初回起動時に新規登録が表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('新規登録'), findsOneWidget);
    expect(find.text('アカウントを作成'), findsOneWidget);
  });

  testWidgets('2回目以降はダミーログインが表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_launched_v1': true});

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('ダミーログイン'), findsOneWidget);
    expect(find.text('田中 太郎'), findsOneWidget);
    expect(find.text('鈴木 花子'), findsOneWidget);
  });
}

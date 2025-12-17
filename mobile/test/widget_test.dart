// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:p2hacks_onyx/app.dart';

void main() {
  testWidgets('起動時にダミーログインが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('ダミーログイン'), findsOneWidget);
    expect(find.text('田中 太郎'), findsOneWidget);
    expect(find.text('鈴木 花子'), findsOneWidget);
  });
}

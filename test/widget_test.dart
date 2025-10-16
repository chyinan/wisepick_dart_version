// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wisepick_dart_version/main.dart';

void main() {
  testWidgets('App shows chat title', (WidgetTester tester) async {
    // 包裹 ProviderScope 后启动应用并触发一帧
    await tester.pumpWidget(const ProviderScope(child: WisePickApp()));
    // 切换到底部导航的「关于」页，再验证页面中的标题文本存在
    // 先等待一帧以完成初始渲染
    await tester.pumpAndSettle();
    // 点击底部导航的关于项（标签文本为 '关于'）
    final aboutFinder = find.text('关于');
    expect(aboutFinder, findsWidgets);
    await tester.tap(aboutFinder.first);
    await tester.pumpAndSettle();

    // 验证关于页中的标题文本出现在页面上
    expect(find.text('快淘帮 — WisePick'), findsOneWidget);
  });
}

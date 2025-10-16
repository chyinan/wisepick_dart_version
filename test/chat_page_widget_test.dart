import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisepick_dart_version/main.dart';
import 'package:wisepick_dart_version/features/chat/chat_providers.dart';
import 'package:wisepick_dart_version/features/chat/chat_service.dart';
import 'package:wisepick_dart_version/core/api_client.dart';

class _FakeChatService extends ChatService {
  _FakeChatService() : super(client: ApiClient());

  @override
  Future<String> getAiReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return '根据您的需求（"$prompt"），推荐：示例商品 — ¥299\n下单链接：https://example.com/product/12345?aff=aff';
  }
}

void main() {
  testWidgets('ChatPage send message and show AI reply', (WidgetTester tester) async {
    // Override ChatService to return deterministic fast mock
    final fake = _FakeChatService();
    final svcOverride = chatServiceProvider.overrideWithValue(fake);

    await tester.pumpWidget(ProviderScope(overrides: [svcOverride], child: const WisePickApp()));
    await tester.pumpAndSettle();

    // Enter text in input
    final Finder input = find.byType(TextField).first;
    expect(input, findsOneWidget);
    await tester.enterText(input, '我想要一款降噪耳机');
    await tester.tap(find.byIcon(Icons.send));

    // wait for AI async reply to appear
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Expect to find '下单链接' in ai reply text
    expect(find.textContaining('下单链接'), findsWidgets);
  });
}


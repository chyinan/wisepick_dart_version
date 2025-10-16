import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisepick_dart_version/main.dart';
import 'package:wisepick_dart_version/features/chat/chat_providers.dart';
import 'package:wisepick_dart_version/features/chat/chat_service.dart';
import 'package:wisepick_dart_version/features/cart/cart_providers.dart';
import 'package:wisepick_dart_version/features/cart/cart_service.dart';
import 'package:wisepick_dart_version/features/products/product_model.dart';

class _FakeChatService extends ChatService {
  @override
  Future<String> getAiReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return '根据您的需求（"$prompt"），推荐：示例商品 — ¥299\n下单链接：https://example.com/product/12345?aff=aff';
  }
}

class _FakeCartService implements CartService {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<void> addOrUpdateItem(ProductModel p, {int qty = 1}) async {
    final existing = _store[p.id];
    if (existing != null) {
      existing['qty'] = (existing['qty'] as int) + qty;
    } else {
      final m = p.toMap();
      m['qty'] = qty;
      _store[p.id] = m;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllItems() async => _store.values.map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Future<void> removeItem(String productId) async {
    _store.remove(productId);
  }

  @override
  Future<void> setQuantity(String productId, int qty) async {
    final existing = _store[productId];
    if (existing != null) existing['qty'] = qty;
  }

  @override
  Future<void> clear() async => _store.clear();
}

void main() {
  testWidgets('Chat -> AI reply -> add to cart', (WidgetTester tester) async {
    final fakeChat = _FakeChatService();
    final fakeCart = _FakeCartService();

    final svcOverride = chatServiceProvider.overrideWithValue(fakeChat as ChatService);
    final cartSvcOverride = cartServiceProvider.overrideWithValue(fakeCart as dynamic);
    final itemsOverride = cartItemsProvider.overrideWithProvider(FutureProvider<List<Map<String, dynamic>>>((ref) async => await fakeCart.getAllItems()));

    await tester.pumpWidget(ProviderScope(overrides: [svcOverride, cartSvcOverride, itemsOverride], child: const WisePickApp()));
    await tester.pumpAndSettle();

    // send message
    final Finder input = find.byType(TextField).first;
    await tester.enterText(input, '我要耳机');
    await tester.tap(find.byIcon(Icons.send));

    // wait for reply and rendering
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // product card should appear
    expect(find.textContaining('示例商品'), findsWidgets);

    // tap favorite (add to cart) icon inside first ProductCard
    final fav = find.byIcon(Icons.favorite_border).first;
    await tester.tap(fav);
    await tester.pumpAndSettle();

    // fakeCart should contain item
    final items = await fakeCart.getAllItems();
    expect(items.isNotEmpty, true);
  });
}


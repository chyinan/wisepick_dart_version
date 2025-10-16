import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_service.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

final cartItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(cartServiceProvider);
  return svc.getAllItems();
});

/// 简单的 Provider 保存购物车界面的本地选择状态（非持久化）
final cartSelectionProvider = StateProvider<Map<String, bool>>((ref) => <String, bool>{});


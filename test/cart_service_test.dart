import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisepick_dart_version/features/cart/cart_service.dart';
import 'package:wisepick_dart_version/features/products/product_model.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartService', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      Hive.registerAdapter(ProductModelAdapter());
    });

    tearDownAll(() async {
      try {
        await Hive.deleteFromDisk();
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('add, update, remove item', () async {
      final svc = CartService();
      final sample = ProductModel(
        id: 't1',
        title: 'test',
        description: 'd',
        price: 10.0,
        imageUrl: '',
        sourceUrl: '',
        rating: 4.0,
        reviewCount: 1,
      );

      await svc.clear();
      await svc.addOrUpdateItem(sample, qty: 2);
      var items = await svc.getAllItems();
      expect(items.length, 1);
      expect(items.first['qty'], 2);

      await svc.setQuantity('t1', 5);
      items = await svc.getAllItems();
      expect(items.first['qty'], 5);

      await svc.removeItem('t1');
      items = await svc.getAllItems();
      expect(items.isEmpty, true);
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:wisepick_dart_version/features/products/pdd_adapter.dart';

void main() {
  test('PddAdapter.search should not throw and return List when gateway unreachable', () async {
    final adapter = PddAdapter();
    final results = await adapter.search('测试', page: 1, pageSize: 10);
    expect(results, isA<List>());
  });
}


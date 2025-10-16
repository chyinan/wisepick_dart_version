import 'dart:convert';
import 'dart:io';

import '../lib/core/pdd_client.dart';
import '../lib/core/config.dart';

Future<void> main(List<String> args) async {
  // 打印环境变量，用于调试
  print('--- PDD Config ---');
  print('PDD_CLIENT_ID: ${Config.pddClientId}');
  print('PDD_CLIENT_SECRET: ${Config.pddClientSecret}');
  print('PDD_PID: ${Config.pddPid}');
  print('--------------------');
  
  final keyword = args.isNotEmpty ? args.join(' ') : 'iPhone17';
  final client = PddClient(clientId: Config.pddClientId, clientSecret: Config.pddClientSecret, pid: Config.pddPid);

  final biz = <String, dynamic>{
    'keyword': keyword,
    'page': 1,
    'page_size': 10,
    'pid': Config.pddPid,
    'with_coupon': false,
  };

  print('Searching PDD for "$keyword" ...');
  final resp = await client.searchGoods(biz);

  if (resp is Map && resp['error'] == true) {
    stderr.writeln('PDD request error: ${resp['message']}');
    if (resp['details'] != null) stderr.writeln('details: ${resp['details']}');
    exit(1);
  }

  try {
    final Map<String, dynamic> body = (resp is Map && resp['goods_search_response'] != null)
        ? Map<String, dynamic>.from(resp['goods_search_response'] as Map)
        : (resp is Map ? Map<String, dynamic>.from(resp) : {});

    final List items = body['goods_list'] is List ? body['goods_list'] as List : (body['goods_list'] != null ? [body['goods_list']] : []);
    if (items.isEmpty) {
      print('No goods returned. Raw response:');
      print(JsonEncoder.withIndent('  ').convert(resp));
      return;
    }

    for (int i = 0; i < items.length && i < 10; i++) {
      final it = Map<String, dynamic>.from(items[i] as Map);
      final name = it['goods_name'] ?? it['opt_name'] ?? '';
      final sign = it['goods_sign'] ?? '';
      final image = it['goods_image_url'] ?? it['goods_thumbnail_url'] ?? '';
      final minGroup = (it['min_group_price'] is num) ? (it['min_group_price'] / 100.0) : (double.tryParse((it['min_group_price'] ?? '0').toString()) ?? 0) / 100.0;
      final minNorm = (it['min_normal_price'] is num) ? (it['min_normal_price'] / 100.0) : (double.tryParse((it['min_normal_price'] ?? '0').toString()) ?? 0) / 100.0;
      final coupon = (it['coupon_discount'] is num) ? (it['coupon_discount'] / 100.0) : (double.tryParse((it['coupon_discount'] ?? '0').toString()) ?? 0) / 100.0;
      final promo = (it['promotion_rate'] is num) ? (it['promotion_rate'] as num) : (int.tryParse((it['promotion_rate'] ?? '0').toString()) ?? 0);

      print('--- #${i + 1} ---');
      print('name: $name');
      print('goods_sign: $sign');
      print('price (group): ¥${minGroup.toStringAsFixed(2)}  normal: ¥${minNorm.toStringAsFixed(2)}  coupon: ¥${coupon.toStringAsFixed(2)}');
      print('promotion_rate (‰): $promo');
      print('image: $image');
    }
  } catch (e) {
    stderr.writeln('Failed to parse PDD response: $e');
    print(JsonEncoder.withIndent('  ').convert(resp));
  }
}


import 'dart:io';
import 'dart:convert';
import '../lib/core/api_client.dart';
import '../lib/core/jd_sign.dart';
import '../lib/core/config.dart';

Future<void> main(List<String> args) async {
  final keyword = args.isNotEmpty ? args[0] : (Platform.environment['JD_SEARCH_KEYWORD'] ?? '耳机');
  final accessToken = Platform.environment['JD_TEST_ACCESS_TOKEN'] ?? '';
  if (accessToken.isEmpty) {
    print('[ERROR] JD_TEST_ACCESS_TOKEN not set.');
    exit(1);
  }

  final biz = <String, dynamic>{
    'clientId': '1',
    'pageSize': 20,
    'pageIndex': 1,
    'keyword': keyword,
  };
  final bizParams = jsonEncode(biz);

  final params = <String, String>{
    'method': 'jingdong.searchSku',
    'access_token': accessToken,
    'app_key': Config.jdAppKey,
    'timestamp': (() {
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
    })(),
    'v': '2.0',
    'format': 'json',
    '360buy_param_json': bizParams,
  };

  final sign = computeJdSign(params, Config.jdAppSecret);
  params['sign'] = sign;

  print('[DEBUG] request params:');
  params.forEach((k, v) => print('  $k: $v'));

  final client = ApiClient();
  try {
    final resp = await client.post('https://api.jd.com/routerjson', data: params, headers: {'content-type': 'application/x-www-form-urlencoded'});
    print('[DEBUG] status: ${resp.statusCode}');
    print('[DEBUG] headers: ${resp.headers.map}');
    print('[DEBUG] data: ${resp.data}');
  } catch (e, st) {
    print('[ERROR] call error: $e');
    print(st);
  }
}
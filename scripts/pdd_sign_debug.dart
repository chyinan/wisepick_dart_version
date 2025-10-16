import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

String stringifyValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return jsonEncode(value);
}

void main(List<String> args) async {
  final env = Platform.environment;
  final clientId = env['PDD_CLIENT_ID'] ?? '';
  final clientSecret = env['PDD_CLIENT_SECRET'] ?? '';
  final pid = env['PDD_PID'] ?? '';

  if (clientId.isEmpty || clientSecret.isEmpty) {
    stderr.writeln('PDD_CLIENT_ID or PDD_CLIENT_SECRET not set');
    exit(1);
  }

  final keyword = args.isNotEmpty ? args.join(' ') : 'iPhone17';
  final custom = jsonEncode({'uid': 'chyinan'});

  final allParams = <String, dynamic>{
    'client_id': clientId,
    'type': 'pdd.ddk.goods.search',
    'data_type': 'JSON',
    'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    'keyword': keyword,
  };
  if (pid.isNotEmpty) allParams['pid'] = pid;
  allParams['custom_parameters'] = custom;

  final keys = allParams.keys.map((k) => k.toString()).toList()..sort();
  final sb = StringBuffer();
  sb.write(clientSecret);
  for (final k in keys) {
    final v = allParams[k];
    if (v == null) continue;
    sb.write(k);
    sb.write(stringifyValue(v));
  }
  sb.write(clientSecret);

  final base = sb.toString();
  final sign = md5.convert(utf8.encode(base)).toString().toUpperCase();

  print('--- SIGN DEBUG ---');
  print('client_id: $clientId');
  print('pid: $pid');
  print('timestamp: ${allParams['timestamp']}');
  print('sorted keys: $keys');
  print('\nsign base string:\n$base\n');
  print('computed sign: $sign\n');

  // build form body as PddClient does
  final form = <String, String>{};
  allParams.forEach((k, v) {
    if (v == null) return;
    if (v is List || v is Map) form[k] = jsonEncode(v);
    else form[k] = v.toString();
  });
  form['sign'] = sign;

  // send directly to PDD gateway
  try {
    final resp = await http.post(Uri.parse('https://gw-api.pinduoduo.com/api/router'), headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: form).timeout(Duration(seconds: 10));
    print('pdd response status: ${resp.statusCode}');
    print('pdd response body: ${resp.body}');
  } catch (e) {
    stderr.writeln('pdd direct call failed: $e');
  }
}


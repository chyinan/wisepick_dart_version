import 'dart:convert';
import 'package:crypto/crypto.dart';

String computeJdSign(Map<String, String> params, String appSecret) {
  // 京东签名示例（常见方式）：secret + k1v1k2v2... + secret，然后 MD5 大写
  // 注意：请以官方文档为准，这里为常见占位实现，生产环境请替换为官方算法
  final keys = params.keys.toList()..sort();
  final buffer = StringBuffer();
  buffer.write(appSecret);
  for (final k in keys) {
    final v = params[k] ?? '';
    buffer.write('$k$v');
  }
  buffer.write(appSecret);
  final bytes = utf8.encode(buffer.toString());
  final digest = md5.convert(bytes);
  return digest.toString().toUpperCase();
}
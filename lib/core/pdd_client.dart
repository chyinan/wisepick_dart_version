import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'api_client.dart';

/// 简单的 PDD 客户端，负责签名并调用多多进宝商品搜索接口（pdd.ddk.goods.search）
class PddClient {
  final String clientId;
  final String clientSecret;
  final String pid;
  final String baseUrl;
  final ApiClient apiClient;

  PddClient({
    required this.clientId,
    required this.clientSecret,
    required this.pid,
    ApiClient? apiClient,
    this.baseUrl = 'https://gw-api.pinduoduo.com/api/router',
  }) : apiClient = apiClient ?? ApiClient();

  String _stringifyValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    // 对 List/Map 使用紧凑 JSON 编码
    return jsonEncode(value);
  }

  String _generateSign(Map<String, dynamic> params) {
    final keys = params.keys.map((k) => k.toString()).toList()..sort();
    final buffer = StringBuffer();
    buffer.write(clientSecret);
    for (final k in keys) {
      final v = params[k];
      if (v == null) continue;
      buffer.write('$k${_stringifyValue(v)}');
    }
    buffer.write(clientSecret);
    final bytes = utf8.encode(buffer.toString());
    final digest = md5.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// 调用 pdd.ddk.goods.search
  /// [bizParams] 是业务参数（如 keyword, page, page_size, opt_id, range_list 等）
  Future<dynamic> searchGoods(Map<String, dynamic> bizParams, {String? accessToken}) async {
    final Map<String, dynamic> allParams = {
      'client_id': clientId,
      'type': 'pdd.ddk.goods.search',
      'data_type': 'JSON',
      'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };

    // 合并业务参数（保留原始类型以便签名时编码）
    for (final entry in bizParams.entries) {
      allParams[entry.key] = entry.value;
    }

    if (accessToken != null) {
      allParams['access_token'] = accessToken;
    }

    // 生成签名
    final sign = _generateSign(allParams);

    // 构建请求体：PDD 要求 form-urlencoded 格式，注意对数组/对象参数进行 JSON 编码
    final Map<String, dynamic> body = {};
    allParams.forEach((k, v) {
      if (v == null) return;
      if (v is List || v is Map) body[k] = jsonEncode(v);
      else body[k] = v.toString();
    });
    body['sign'] = sign;

    try {
      final response = await apiClient.post(baseUrl, data: FormData.fromMap(body));
      return response.data;
    } on DioException catch (e) {
      // 统一返回错误信息，调用方可根据需要处理
      return {'error': true, 'message': e.message ?? e.toString(), 'details': e.response?.data};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }
}


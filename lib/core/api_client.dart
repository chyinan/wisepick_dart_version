import 'package:dio/dio.dart';

/// 简单的 Dio 封装，统一处理错误与响应
class ApiClient {
  final Dio dio;

  ApiClient({Dio? dio}) : dio = dio ?? Dio() {
    // 全局配置示例：将接收超时调大以支持长时间流式响应（如大模型流式输出）
    this.dio.options.connectTimeout = const Duration(seconds: 30);
    this.dio.options.receiveTimeout = const Duration(minutes: 5);
  }

  /// GET 请求封装
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final resp = await dio.get(path, queryParameters: params);
      return resp;
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// POST 请求封装
  /// Optional headers and responseType can be provided for per-request customization.
  /// POST 请求封装
  /// Optional headers, responseType and per-request timeouts can be provided.
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers, ResponseType? responseType}) async {
    try {
      final options = Options(headers: headers, responseType: responseType);
      final resp = await dio.post(path, data: data, options: options);
      return resp;
    } on DioException catch (_) {
      rethrow;
    }
  }
}


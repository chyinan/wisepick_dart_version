import '../products/product_model.dart';

/// ChatMessage 用于 chat 模块，包装通用的 Message 或扩展字段
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final ProductModel? product;
  final List<ProductModel>? products;
  final List<String>? keywords;
  final List<dynamic>? attempts; // 后端返回的尝试元信息（可用于调试或展示兜底提示）
  final String? aiParsedRaw; // 原始 AI 解析后的结构化 JSON 字符串（可选，用于商品详情页显示 AI 推荐理由）
  final bool failed;
  final String? retryForText;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.product,
    this.products,
    this.keywords,
    this.attempts,
    this.aiParsedRaw,
    this.failed = false,
    this.retryForText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}


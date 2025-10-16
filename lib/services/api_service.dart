// ApiService 抽象定义与 Mock 实现
// 后续可在这里实现真实的 HTTP 客户端和解析逻辑

abstract class ApiService {
  /// 根据用户的查询返回推荐文本（异步）
  Future<String> getRecommendation(String userQuery);
}

/// Mock 实现：返回示例推荐（便于前端开发和单元测试）
class MockApiService implements ApiService {
  @override
  Future<String> getRecommendation(String userQuery) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final String sampleProductName = '示例商品：无线降噪耳机 Pro';
    final String samplePrice = '¥299';
    final String sampleShortDesc =
        '性价比高，续航 30 小时，主动降噪，适合通勤与办公。';
    final String sampleOrderUrl = 'https://example.com/product/12345?aff=your_aff_id';

    return '根据您的需求（"$userQuery"），推荐如下：\n'
        '$sampleProductName — $samplePrice\n'
        '$sampleShortDesc\n'
        '下单链接：$sampleOrderUrl\n'
        '（这是模拟推荐，后端接入后将提供实时比价和评论分析）';
  }
}


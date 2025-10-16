import '../../core/api_client.dart';
import '../../core/jd_oauth_service.dart';
import '../../core/jd_sign.dart';
import '../../core/config.dart';

class JdProductServiceExtension {
  final ApiClient client;
  final JdOAuthService jdOAuthService;
  final String serviceUserId;

  JdProductServiceExtension({required this.client, required this.jdOAuthService, required this.serviceUserId});

  /// 根据 wareId 获取图片列表
  Future<dynamic> findImagesByWareId(String wareId) async {
    // 1. 取后端单账号 access_token
    final accessToken = await jdOAuthService.getAccessTokenForUser(serviceUserId);
    if (accessToken == null) throw StateError('no access token for JD service account');

    // 2. 构造公共参数（字符串map）
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll('T', ' ').split('.').first;
    final params = <String, String>{
      'method': 'jingdong.image.read.findImagesByWareId',
      'access_token': accessToken,
      'app_key': Config.jdAppKey,
      'timestamp': timestamp,
      'v': '2.0',
      'format': 'json',
      'wareId': wareId,
    };

    // 3. 计算签名（请在生产中校验官方算法）
    final sign = computeJdSign(params, Config.jdAppSecret);
    params['sign'] = sign;

    // 4. 发起请求（京东通常用 router.json endpoint）
    final resp = await client.post('https://api.jd.com/routerjson', data: params);
    return resp.data;
  }
}
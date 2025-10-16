import 'jd_oauth_service.dart';
import 'oauth_state_store.dart';

class OAuthCallbackHandler {
  final JdOAuthService jdOAuthService;
  final OAuthStateStore stateStore;

  OAuthCallbackHandler({required this.jdOAuthService, required this.stateStore});

  /// 处理回调：校验 state 并用 code 换取 token
  Future<bool> handleCallback({required String state, required String code, required String adminUserId, required String redirectUri}) async {
    final valid = stateStore.consume(state);
    if (!valid) return false;
    // 用 jdOAuthService 完成 code -> token 并存储
    await jdOAuthService.handleAuthorizationCallback(userId: adminUserId, code: code, redirectUri: redirectUri);
    return true;
  }
}
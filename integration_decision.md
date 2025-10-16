# 集成决策：在现有项目中接入京东 OAuth

说明：本文件基于仓库现有 `ApiClient`（Dio 封装）和 `Config` 占位配置，给出两种实现方案、权衡与推荐实现细节（含伪代码）。

```1:38:lib/core/api_client.dart
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
```

```1:20:lib/core/config.dart
// 全局配置和常量
// 注意：实际发布前不要把真实 API Key 写在源码中，使用安全存储或 CI 注入

class Config {
  // 京东联盟配置占位
  static const String jdAppKey = 'YOUR_JD_APP_KEY';
  static const String jdAppSecret = 'YOUR_JD_APP_SECRET';
  static const String jdUnionId = 'YOUR_JD_UNION_ID';
}
```

关键前提：
- `ApiClient` 使用 `Dio`，可以通过 `dio.interceptors` 注入鉴权逻辑。  
- `Config` 里已有 `jdAppKey/jdAppSecret` 占位，但**不要在源码中存放真实密钥**；应使用环境变量或密钥管理服务。

方案 A — 在 `ApiClient` 中直接实现 OAuth（紧耦合）
- 描述：在 `ApiClient` 构造时注入一个 `TokenProvider`，并在请求拦截器中读取 token 注入 `Authorization`；在收到 401 时由同一模块负责刷新 token 并重试。
- 优点：实现位置集中，调用方无感知；方便同步所有外部请求。  
- 缺点：把 OAuth 复杂逻辑塞进通用 Http 客户端会使其职责膨胀，影响可测试性与复用性；不同用户/场景的 token 管理（按用户/按站点）变得复杂。

方案 B（推荐）— 独立 `JdOAuthService` + 在 `ApiClient` 注入最小接口（松耦合）
- 描述：实现独立的 `JdOAuthService` 负责所有与京东授权相关的逻辑（构造授权 URL、回调处理、token 交换、存储、刷新、撤销）；`ApiClient` 只暴露一个可挂钩的 `getAccessToken(userId)` 回调或在 Dio 拦截器中依赖 `JdOAuthService` 的 `getAccessTokenForRequest(requestContext)`。
- 优点：符合单一职责原则；更易维护、测试与复用；不同平台（Web/App/Server）授权流程逻辑集中在服务层。  
- 缺点：需要在请求上下文中传递 userId（或 access token key），实现略复杂但更健壮。

实现要点（推荐 B）：
1. `JdOAuthService` 职责
   - 构造授权 URL 并生成 `state`（防 CSRF）
   - 处理 OAuth 回调：校验 `state`，用 code 换取 token（access_token/refresh_token），加密后存储
   - 提供 `getAccessTokenForUser(userId)`：返回当前可用 access_token；若即将过期或无效，则触发刷新流程
   - 提供 `refreshAccessToken(refreshToken)`：执行刷新并原子更新存储
   - 提供 `revoke`、`rotateClientSecret` 等运维接口

2. `ApiClient` 与 `Dio` 的集成（伪代码）
```dart
// 伪代码示例：把 JdOAuthService 注入 ApiClient
final jdOAuthService = JdOAuthService(store: tokenStore);
final apiClient = ApiClient(dio: Dio());

apiClient.dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final userId = options.extra['userId'] as String?; // 请求上下文传 userId
    if (userId != null) {
      final token = await jdOAuthService.getAccessTokenForUser(userId);
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
  onError: (err, handler) async {
    final resp = err.response;
    if (resp?.statusCode == 401) {
      // 单-flight 刷新：防止并发刷新
      await jdOAuthService.refreshIfNeededForRequest(err.requestOptions);
      // 重试原始请求
      final opts = err.requestOptions;
      final newReq = await apiClient.dio.fetch(opts);
      return handler.resolve(newReq);
    }
    handler.next(err);
  }
));
```

3. 并发刷新控制
- 在分布式环境下推荐使用 Redis 锁或数据库乐观锁，单实例可用 in-memory mutex/Completer 单飞策略（single-flight）。

4. Token 存储与安全
- access_token：短期保存在 Redis（加密）或内存缓存以加速请求；refresh_token：加密后存储于数据库或机密服务（Vault、KMS）
- client_secret、appKey：使用 CI/环境变量或专用 Secret Manager（不要写入源码）

5. 回调与 CSRF
- 授权发起时生成随机 `state` 保存于会话（或短期 DB），回调时必须校验 `state`。
- 对于移动端使用 `PKCE`（如官方支持）能避免 client_secret 泄露问题。

6. 是否需要扫码或 APP 内授权？
- 需以官方帮助中心为准；若官方仅支持网页授权，移动端应使用系统浏览器或 in-app browser + universal link/app-scheme 回调；如果官方提供扫码或 APP 唤醒方案，可在 `mobile_oauth_integration.md` 中列出实现要点。

验收要点（Acceptance Criteria）
- `JdOAuthService` 能完成授权码换 token、刷新与撤销流程（有单元/集成测试覆盖）
- `ApiClient` 请求在有 `userId` 上下文时自动注入 `Authorization` 并能在 401 时完成刷新并重试（处理并发刷新）
- 所有密钥从环境/密钥管理服务注入，源码无明文凭证
- 提供 `mobile_oauth_integration.md` 与 `jd_oauth_api_contract.yaml`（API Contract）

建议时间估算（实现 B）
- 设计与 API Contract：0.5 天
- `JdOAuthService` 基本实现（含伪代码与单元测试）：2 天
- ApiClient 集成与并发刷新处理：1 天
- 集成测试与运维文档：1 天

---

下一步：我将把本文件保存到仓库（已生成），并将任务 `设计后端 OAuth 接入接口与 API Contract` 设为进行中（task-3）。如需我现在生成 `jd_oauth_api_contract.yaml` 的草案，我可以继续。
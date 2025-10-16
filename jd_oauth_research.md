# 京东 OAuth 调研记录

> 说明：本文件只引用官方或可靠开源资料的事实与可验证结论（不做未经验证的假设）。我们**不接入**第三方付费服务（如 VEAPI），仅使用官方开放平台资料与 SDK/示例代码作为依据。

1) 官方文档入口（权威）
- 京东联盟帮助中心 / 官方文档（SDK README 也引用此入口）：
  - https://union.jd.com/helpcenter/13246-13247-46301

2) 已检索到的事实与要点（基于官方/开源资料）
- 授权与凭证：调用需要授权的京东联盟接口通常要求开发者在京东联盟后台完成注册/授权，获取 `appKey` / `appSecret`、`unionId`、以及推广位 `positionId`/PID 等凭证。
- 接入前置：部分接口在调用前要求会员中心的“授权/绑定”步骤完成（文档/SDK、示例均提示需先授权）。
- SDK 及示例：社区/开源 SDK（例如 jd-union-sdk）和若干客户端 Demo 提供了使用 `appKey`/`secretKey` 调用 API 的样例，表明服务端与客户端均有实现授权/鉴权的实践。
  - jd-union-sdk README: https://github.com/joneqian/jd-union-sdk
  - 客户端 OAuth 示例（实现京东 OAuth 的 Demo）：https://github.com/WesleyQ5233/QWGoJDDemo

3) 未决问题（需在官方帮助中心或控制台确认）
- 官方是否对外明确支持 OAuth2 的标准授权码流（authorization_code）、PKCE、或扫码/APP 内授权等特定流；以及对应的授权端点与 token 端点详细规范。
- 是否存在服务端到服务端（client_credentials）类型的接口可用以避免用户交互（若有可用于非用户授权场景）。

4) 下一步行动（可直接执行）
- 立即打开并记录官方 HelpCenter / 开发者控制台中的“授权流程”页面并摘录授权端点与示例（确认为任务 1 的产物）。
- 在本仓库中查找 `ApiClient` 与 `config`（我已并行读取 `lib/core/api_client.dart` 与 `lib/core/config.dart`，后续会把发现写入 `integration_decision.md`）。

5) 参考链接（仅官方或开源）
- 官方：https://union.jd.com/helpcenter/13246-13247-46301
- SDK/示例：
  - https://github.com/joneqian/jd-union-sdk
  - https://github.com/WesleyQ5233/QWGoJDDemo

---

记录人：自动化调研（由开发助理生成），后续会把官方授权端点与示例复制到本文件并更新。
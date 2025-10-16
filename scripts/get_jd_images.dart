import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../lib/core/api_client.dart';
import '../lib/core/jd_oauth_service.dart';
import '../lib/core/oauth_state_store.dart';
import '../lib/core/oauth_controller.dart';
import '../lib/core/oauth_callback.dart';
import '../lib/features/products/jd_product_service_extension.dart';
import '../lib/core/config.dart';

Future<void> main(List<String> args) async {
  final apiClient = ApiClient();
  final tokenStore = InMemoryTokenStore();
  final jdOAuthService = JdOAuthService(apiClient: apiClient, tokenStore: tokenStore);
  final stateStore = OAuthStateStore();
  final oauthController = OAuthController(jdOAuthService: jdOAuthService, stateStore: stateStore);
  final callbackHandler = OAuthCallbackHandler(jdOAuthService: jdOAuthService, stateStore: stateStore);

  print('--- JD 后端单账号授权（交互式）脚本 ---');

  final jdAppKey = Config.jdAppKey;
  final jdAppSecret = Config.jdAppSecret;
  if (jdAppKey.startsWith('YOUR_JD_APP_KEY') || jdAppSecret.startsWith('YOUR_JD_APP_SECRET')) {
    print('请先通过环境变量设置 JD_APP_KEY 与 JD_APP_SECRET（避免把密钥写入源码）');
    print('Windows CMD 示例:');
    print('  set JD_APP_KEY=d26362a7d1037522f81c57afc70a78e7');
    print('  set JD_APP_SECRET=YOUR_SECRET');
    exit(1);
  }

  // 回调地址优先从环境变量 JD_REDIRECT_URI 读取（应与京东控制台中登记的回调地址一致），否则回落到本地监听
  final redirectUri = (Platform.environment['JD_REDIRECT_URI'] ?? '').trim().isNotEmpty
      ? Platform.environment['JD_REDIRECT_URI']!.trim()
      : 'http://localhost:3000/oauth/callback';

  // 生成授权 URL
  final auth = oauthController.authorize(redirectUri: redirectUri);
  final authorizeUrl = auth['authorize_url'] as String;
  final state = auth['state'] as String;
  // 打印以便复制使用
  print('\n[INFO] 授权地址（复制到浏览器打开）:');
  print(authorizeUrl);
  print('[INFO] state: $state');

  // 如果 redirectUri 指向本地（localhost/127.0.0.1），则启动本地回调监听并自动接收；
  // 否则切换到手动粘贴模式，用户在浏览器完成授权后将重定向到外部域（如 kepler），脚本无法自动接收回调。
  final redirectHost = Uri.parse(redirectUri).host;
  final isLocalRedirect = redirectHost == 'localhost' || redirectHost == '127.0.0.1' || redirectHost == '::1';

  if (isLocalRedirect) {
    // 启动 HTTP server 监听回调
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    print('\n启动本地回调监听：$redirectUri');

    // 在浏览器打开授权 URL（尝试）
    try {
      if (Platform.isWindows) {
        await Process.run('powershell', ['-Command', 'Start-Process', authorizeUrl]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [authorizeUrl]);
      } else {
        await Process.run('xdg-open', [authorizeUrl]);
      }
    } catch (_) {
      print('无法自动打开浏览器，请手动访问：');
      print(authorizeUrl);
    }

    print('等待授权回调... (在浏览器完成授权)');

    await for (HttpRequest req in server) {
      if (req.uri.path == Uri.parse(redirectUri).path) {
        final params = req.uri.queryParameters;
        final code = params['code'];
        final rstate = params['state'];
        print('\n[DEBUG] 接收到回调请求，query: ${req.uri.query}');
        if (code == null || rstate == null) {
          req.response
            ..statusCode = 400
            ..write('Missing code or state')
            ..close();
          continue;
        }

        // 消费 state 并处理 token
        final ok = await callbackHandler.handleCallback(state: rstate, code: code, adminUserId: 'service_account', redirectUri: redirectUri);
        if (ok) {
          req.response
            ..statusCode = 200
            ..write('授权成功，可以关闭此页并回到终端')
            ..close();
          print('授权成功，token 已保存。');

          // 关闭 server 并继续
          await server.close(force: true);
          break;
        } else {
          req.response
            ..statusCode = 400
            ..write('state 验证失败')
            ..close();
        }
      } else {
        req.response
          ..statusCode = 404
          ..write('Not found')
          ..close();
      }
    }
  } else {
    // 手动粘贴模式：打印说明并等待用户粘贴回调 URL 或直接粘 code
    print('\n本次回调使用外部域（$redirectHost），脚本无法自动接收回调。');
    print('授权后请把浏览器地址栏的完整重定向 URL（或只复制 ?code=... 的 code 值）粘回此终端，然后回车。');
    stdout.write('请输入完整回调 URL 或 code: ');
    final input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) {
      print('未输入回调信息，退出');
      exit(1);
    }

    String? codeFromUser;
    // 如果用户粘贴的是完整 URL，解析其中的 code
    try {
      final maybeUri = Uri.parse(input.trim());
      if (maybeUri.queryParameters.containsKey('code')) {
        codeFromUser = maybeUri.queryParameters['code'];
      }
    } catch (_) {}
    // 如果直接粘 code，则直接使用
    codeFromUser ??= input.trim();

    // 用 code 换 token
    final token = await jdOAuthService.exchangeCodeForToken(code: codeFromUser, redirectUri: redirectUri);
    if (token == null) {
      print('Token 交换失败，请检查 code、app_key 与 app_secret 是否正确，或稍后重试');
      exit(1);
    }
    // 保存 token 到示例存储
    await tokenStore.saveTokens('service_account', token);
    // 持久化到文件 tmp_jd_token.json
    final file = File('tmp_jd_token.json');
    await file.writeAsString(jsonEncode(token.toJson()));
    print('授权成功，token 已保存到示例存储并写入 tmp_jd_token.json。');
  }

  // 授权完成，继续查询 wareId
  stdout.write('\n请输入要查询的 wareId：');
  final wareId = stdin.readLineSync();
  if (wareId == null || wareId.trim().isEmpty) {
    print('wareId 为空，退出');
    exit(1);
  }

  final jdExt = JdProductServiceExtension(client: apiClient, jdOAuthService: jdOAuthService, serviceUserId: 'service_account');
  try {
    final resp = await jdExt.findImagesByWareId(wareId.trim());
    print('\n接口返回：');
    print(resp);
  } catch (e, st) {
    print('调用 findImagesByWareId 出错: $e');
    print(st);
    exit(1);
  }

  print('\n完成。');
}
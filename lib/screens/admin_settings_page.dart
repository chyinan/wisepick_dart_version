import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

// config not used here

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final TextEditingController _openAiController = TextEditingController();
  final TextEditingController _affiliateController = TextEditingController();
  final TextEditingController _taobaoAppKeyController = TextEditingController();
  final TextEditingController _taobaoAppSecretController = TextEditingController();
  final TextEditingController _taobaoAdzoneController = TextEditingController();
  final TextEditingController _jdAppKeyController = TextEditingController();
  final TextEditingController _jdAppSecretController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _backendBaseController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  List<String> _models = [];
  bool _loadingModels = false;
  String? _modelError;
  bool _embedPrompts = true;
  bool _debugAiResponse = false;
  bool _copyFullReturn = false;
  bool _useMockAi = false;
  String _maxTokens = 'unlimited';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox('settings');
      final String? openai = box.get('openai_api') as String?;
      final String? affiliate = box.get('veapi_key') as String?;
      final String? backendBase = box.get('backend_base') as String?;
      final String? base = box.get('openai_base') as String?;
      final String? model = box.get('openai_model') as String?;
      final String? taobaoKey = box.get('taobao_app_key') as String?;
      final String? taobaoSecret = box.get('taobao_app_secret') as String?;
      final String? taobaoAdzone = box.get('taobao_adzone') as String?;
      final String? jdKey = box.get('jd_app_key') as String?;
      final String? jdSecret = box.get('jd_app_secret') as String?;
      final bool? embed = box.get('embed_prompts') as bool?;
      final bool? debug = box.get('debug_ai_response') as bool?;
      final bool? copyFull = box.get('copy_full_return') as bool?;
      final bool? mock = box.get('use_mock_ai') as bool?;
      final String? maxT = box.get('max_tokens') as String?;
      if (mounted) {
        setState(() {
          _openAiController.text = openai ?? '';
          _affiliateController.text = affiliate ?? '';
          _baseUrlController.text = base ?? '';
          _backendBaseController.text = backendBase ?? 'http://localhost:8080';
          _modelController.text = model ?? 'gpt-3.5-turbo';
          _taobaoAppKeyController.text = taobaoKey ?? '';
          _taobaoAppSecretController.text = taobaoSecret ?? '';
          _taobaoAdzoneController.text = taobaoAdzone ?? '';
          _jdAppKeyController.text = jdKey ?? '';
          _jdAppSecretController.text = jdSecret ?? '';
          _embedPrompts = embed ?? true;
          _debugAiResponse = debug ?? false;
          _copyFullReturn = copyFull ?? false;
          _useMockAi = mock ?? false;
          _maxTokens = maxT ?? 'unlimited';
        });
      }
      // Attempt to fetch available models after loading settings
      _fetchModels();
    } catch (_) {}
  }

  @override
  void dispose() {
    _openAiController.dispose();
    _affiliateController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('后台管理设置', style: Theme.of(context).textTheme.titleMedium)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('OpenAI API Key', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _openAiController, decoration: InputDecoration(hintText: 'sk-...')),
            const SizedBox(height: 16),
            Text('API Base URL (可选，留空使用默认)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _baseUrlController, decoration: InputDecoration(hintText: 'https://api.openai.com/v1')),
            const SizedBox(height: 16),
            Text('Model (例如 gpt-3.5-turbo 或 gpt-4)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loadingModels)
              Row(children: [const CircularProgressIndicator(), const SizedBox(width: 12), const Text('正在加载可用模型...')])
            else if (_modelError != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('获取模型列表失败: $_modelError', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                TextField(controller: _modelController, decoration: InputDecoration(hintText: '手动输入模型，例如 gpt-3.5-turbo'))
              ])
            else
              DropdownButtonFormField<String>(
                value: _models.contains(_modelController.text) ? _modelController.text : null,
                items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _modelController.text = v;
                  });
                },
                decoration: const InputDecoration(),
                hint: Text(_modelController.text.isNotEmpty ? _modelController.text : '选择模型或稍等自动加载'),
              ),
            const SizedBox(height: 16),
            Text('带货联盟 API Key / Tracking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _affiliateController, decoration: InputDecoration(hintText: '渠道链接模板或 API Key')),
            const SizedBox(height: 12),
            Text('后端 Proxy 地址', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _backendBaseController, decoration: InputDecoration(hintText: 'http://localhost:8080 或 https://api.yourdomain.com')),
            const SizedBox(height: 12),
            // 淘宝配置
            Text('淘宝联盟配置', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _taobaoAppKeyController, decoration: InputDecoration(hintText: 'Taobao App Key')),
            const SizedBox(height: 8),
            TextField(controller: _taobaoAppSecretController, decoration: InputDecoration(hintText: 'Taobao App Secret')),
            const SizedBox(height: 8),
            TextField(controller: _taobaoAdzoneController, decoration: InputDecoration(hintText: 'Taobao Adzone ID')),
            const SizedBox(height: 12),
            // 京东配置
            Text('京东联盟配置', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _jdAppKeyController, decoration: InputDecoration(hintText: 'JD App Key')),
            const SizedBox(height: 8),
            TextField(controller: _jdAppSecretController, decoration: InputDecoration(hintText: 'JD App Secret')),
            const SizedBox(height: 12),
            // 将 max_tokens 提到上面并统一文字样式
            const SizedBox(height: 6),
            Text('max_tokens', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _maxTokens,
              items: ['unlimited','300','800','1000','2000'].map((v) => DropdownMenuItem(value: v, child: Text(v=='unlimited' ? '不限 (unlimited)' : v))).toList(),
              onChanged: (v) { if (v != null) setState(() => _maxTokens = v); },
              decoration: const InputDecoration(),
              hint: Text(_maxTokens=='unlimited' ? '不限 (unlimited)' : _maxTokens),
            ),
            // 主体区域可扩展，开关项以行形式展示，开关置于右侧
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // 嵌入预设提示词
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('嵌入预设提示词', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('在发送到 AI 前自动将用户问题合并到预设的 system/user prompt 中，便于调试开关。', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Switch(value: _embedPrompts, onChanged: (v) => setState(() => _embedPrompts = v)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 显示 AI 原始返回
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('显示 AI 原始返回', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('开启后在聊天中会显示从 AI 返回的完整原始 JSON，便于调试。慎选，可能包含较多信息。', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Switch(value: _debugAiResponse, onChanged: (v) => setState(() => _debugAiResponse = v)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 复制完整返回开关
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('复制完整返回', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('开启后聊天界面右侧的复制按钮将复制 AI 的原始返回（用于调试），关闭则复制展示文本。', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Switch(value: _copyFullReturn, onChanged: (v) => setState(() => _copyFullReturn = v)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 使用本地 Mock AI
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('使用本地 Mock AI', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('启用后应用将使用内置的假后端响应，节约调用真实 API 的费用（仅用于开发/调试）。', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Switch(value: _useMockAi, onChanged: (v) => setState(() => _useMockAi = v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // 将保存/取消按钮放到右下角
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final box = await Hive.openBox('settings');
                        await box.put('openai_api', _openAiController.text.trim());
                        await box.put('openai_base', _baseUrlController.text.trim());
                        await box.put('openai_model', _modelController.text.trim());
                        await box.put('veapi_key', _affiliateController.text.trim());
                        await box.put('taobao_app_key', _taobaoAppKeyController.text.trim());
                        await box.put('taobao_app_secret', _taobaoAppSecretController.text.trim());
                        await box.put('taobao_adzone', _taobaoAdzoneController.text.trim());
                        await box.put('jd_app_key', _jdAppKeyController.text.trim());
                        await box.put('jd_app_secret', _jdAppSecretController.text.trim());
                        await box.put('backend_base', _backendBaseController.text.trim());
                        await box.put('debug_ai_response', _debugAiResponse);
                        await box.put('embed_prompts', _embedPrompts);
                        await box.put('copy_full_return', _copyFullReturn);
                        await box.put('max_tokens', _maxTokens);
                        await box.put('use_mock_ai', _useMockAi);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
                      }
                    },
                    child: Text('保存', style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text('取消', style: Theme.of(context).textTheme.labelLarge)),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _effectiveBase() {
    final b = _baseUrlController.text.trim();
    if (b.isNotEmpty) return b;
    return 'https://api.openai.com';
  }

  String? _effectiveKey() {
    final v = _openAiController.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _fetchModels() async {
    setState(() {
      _loadingModels = true;
      _modelError = null;
      _models = [];
    });
    try {
      final base = _effectiveBase();
      final key = _effectiveKey();
      final dio = Dio();
      final headers = <String, dynamic>{'Content-Type': 'application/json'};
      if (key != null) headers['Authorization'] = 'Bearer $key';

      // Build models URL: support both base like 'https://host' and 'https://host/v1'
      // Normalize by trimming whitespace and removing trailing slashes
      final normalizedBase = base.trim().replaceAll(RegExp(r'/+ '), '');
      final baseNoTrailing = normalizedBase.replaceAll(RegExp(r'/+$'), '');
      String modelsUrl;
      if (RegExp(r'/v1$', caseSensitive: false).hasMatch(baseNoTrailing)) {
        modelsUrl = '$baseNoTrailing/models';
      } else {
        modelsUrl = '$baseNoTrailing/v1/models';
      }
      final resp = await dio.get(modelsUrl, options: Options(headers: headers));
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          _models = list.map((e) => (e as Map<String, dynamic>)['id'] as String).toList();
        }
      } else {
        _modelError = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _modelError = e.toString();
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }
}


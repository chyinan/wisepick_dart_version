import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('错误: 请提供一个京东商品链接或SKU ID作为参数。');
    return;
  }
  final materialInfo = args.first;

  print('正在启动Python伪装脚本...');

  // 确定Python解释器和脚本的路径
  // .venv\Scripts\python.exe 是我们创建的虚拟环境
  final pythonExecutable = Platform.isWindows ? r'.venv\Scripts\python.exe' : '.venv/bin/python';
  final scriptPath = Platform.isWindows ? r'bin\jd_scraper.py' : 'bin/jd_scraper.py';

  try {
    // 启动一个新进程来执行Python脚本
    final process = await Process.start(
      pythonExecutable,
      [scriptPath, materialInfo],
      // runInShell: true, // 在某些环境下可能需要
    );

    String stdoutOutput = '';
    String stderrOutput = '';

    // [最终修正] 指定UTF-8解码
    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutOutput += data;
    });

    // [最终修正] 指定UTF-8解码
    process.stderr.transform(utf8.decoder).listen((data) {
      stderrOutput += data;
    });

    // 等待脚本执行完毕
    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      // 脚本成功执行，解析返回的JSON
      final jsonResult = jsonDecode(stdoutOutput);

      if (jsonResult['status'] == 'success') {
        final content = jsonResult['data'] as String;
        
        // 从返回的完整文案中解析链接和价格
        final linkMatch = RegExp(r'https?://u\.jd\.com/[A-Za-z0-9]+').firstMatch(content);
        final priceMatch = RegExp(r'京东价：¥([0-9]+(?:\.[0-9]+)?)').firstMatch(content);

        print('\n🎉 成功获取推广信息！');
        print('---------------------------------');
        print('商品价格: ¥${priceMatch?.group(1) ?? 'N/A'}');
        print('推广链接: ${linkMatch?.group(0) ?? 'N/A'}');
        print('\n完整文案:');
        print(content);
        print('---------------------------------');

      } else {
        print('\n❌ Python脚本执行失败: ${jsonResult['message']}');
      }
    } else {
      // 脚本执行出错
      print('\n❌ Python脚本启动或执行时发生严重错误 (Exit Code: $exitCode)');
      print('错误详情: $stderrOutput');
    }

  } catch (e) {
    print('\n❌ 启动Python脚本时发生异常: $e');
    print('请确保:');
    print('1. Python虚拟环境 (.venv) 已正确创建并激活。');
    print('2. pyppeteer 和 pyppeteer-stealth 库已成功安装。');
  }
}
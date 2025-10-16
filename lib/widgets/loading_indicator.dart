import 'package:flutter/material.dart';

/// 通用加载指示器
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用主题进度指示器颜色
    return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
  }
}


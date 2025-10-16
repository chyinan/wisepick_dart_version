import 'package:flutter/material.dart';

typedef KeywordCallback = void Function(String keyword);

/// 显示 AI 推荐关键词按钮的组件
class KeywordPrompt extends StatelessWidget {
  final List<String> keywords;
  final KeywordCallback onSelected;

  const KeywordPrompt({super.key, required this.keywords, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keywords.map((k) {
        return ElevatedButton(
          onPressed: () => onSelected(k),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          child: Text(k, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
    );
  }
}


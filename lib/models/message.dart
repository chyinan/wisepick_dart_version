// 消息模型文件
// 负责定义聊天消息的结构，方便后续迁移到 Kotlin 时能一一映射

enum Sender { user, bot }

class Message {
  /// 消息文本
  final String text;

  /// 发送者（用户或机器人）
  final Sender sender;

  /// 时间戳
  final DateTime timestamp;

  Message({required this.text, required this.sender, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}


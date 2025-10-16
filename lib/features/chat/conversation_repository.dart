import 'package:hive_flutter/hive_flutter.dart';

import 'conversation_model.dart';

class ConversationRepository {
  static const _boxName = 'conversations';

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<ConversationModel>> listConversations() async {
    final box = await _openBox();
    final List<ConversationModel> list = [];
    for (final v in box.values) {
      try {
        final m = v as Map;
        list.add(ConversationModel.fromMap(Map<String, dynamic>.from(m)));
      } catch (_) {}
    }
    // sort by timestamp desc
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<ConversationModel?> getConversation(String id) async {
    final box = await _openBox();
    final v = box.get(id);
    if (v == null) return null;
    return ConversationModel.fromMap(Map<String, dynamic>.from(v as Map));
  }

  Future<void> saveConversation(ConversationModel conv) async {
    final box = await _openBox();
    await box.put(conv.id, conv.toMap());
  }

  Future<void> deleteConversation(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
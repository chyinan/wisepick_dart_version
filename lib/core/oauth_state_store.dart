// 简单的 OAuth state 存储，生产环境请使用带 TTL 的外部存储（Redis/DB）并与管理员会话绑定
class OAuthStateStore {
  final Map<String, DateTime> _store = {};

  /// 保存 state（建议同时保存与 admin session 关联）
  void save(String state) {
    _store[state] = DateTime.now().add(const Duration(minutes: 10));
  }

  /// 验证并消费 state，返回 true 表示 state 有效且已移除
  bool consume(String state) {
    final expiresAt = _store[state];
    if (expiresAt == null) return false;
    if (DateTime.now().isAfter(expiresAt)) {
      _store.remove(state);
      return false;
    }
    _store.remove(state);
    return true;
  }
}
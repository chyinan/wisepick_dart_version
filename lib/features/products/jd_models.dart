// JD Union request/response lightweight models used by the adapter.
// Keep this file minimal: only the request DTO needed for searching.

class GoodsReqDTO {
  final String? keyword;
  final int pageIndex;
  final int pageSize;

  GoodsReqDTO({this.keyword, this.pageIndex = 1, this.pageSize = 20});

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'pageIndex': pageIndex, 'pageSize': pageSize};
    if (keyword != null && keyword!.isNotEmpty) m['keyword'] = keyword;
    return m;
  }
}


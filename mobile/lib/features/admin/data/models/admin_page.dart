class AdminPage<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  const AdminPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory AdminPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return AdminPage<T>(
      items: rawItems.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  int get totalPages {
    if (pageSize <= 0) return 1;
    final n = (total / pageSize).ceil();
    return n < 1 ? 1 : n;
  }
}
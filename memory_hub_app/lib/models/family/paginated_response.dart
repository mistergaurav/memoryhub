class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList() ??
        [];
    final total = json['total'] as int? ?? items.length;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? items.length;
    final hasMore = json['has_more'] as bool? ?? (items.length >= pageSize);

    return PaginatedResponse(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) => {
        'items': items.map((item) => toJsonT(item)).toList(),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'has_more': hasMore,
      };
}

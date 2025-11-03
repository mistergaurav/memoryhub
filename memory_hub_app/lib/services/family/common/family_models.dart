class FamilyApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final Map<String, dynamic>? errors;

  FamilyApiResponse({
    this.data,
    this.message,
    this.success = true,
    this.errors,
  });

  factory FamilyApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return FamilyApiResponse<T>(
      data: fromJsonT != null && json['data'] != null 
        ? fromJsonT(json['data']) 
        : null,
      message: json['message']?.toString(),
      success: json['success'] ?? true,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class PaginatedApiResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedApiResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataList = json['data'] as List? ?? json['items'] as List? ?? [];
    return PaginatedApiResponse<T>(
      items: dataList.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      total: json['total'] ?? dataList.length,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? json['pageSize'] ?? 20,
      hasMore: json['has_more'] ?? json['hasMore'] ?? false,
    );
  }
}

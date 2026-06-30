// Mirrors the backend ApiResponse<T> wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<dynamic>? errors;
  final PaginationMeta? pagination;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: fromData != null && json['data'] != null ? fromData(json['data']) : null,
      errors: json['errors'] as List<dynamic>?,
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

// Generic paged result for list screens
class PagedResult<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PagedResult({required this.items, required this.pagination});
}

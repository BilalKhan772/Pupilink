class Pagination<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  const Pagination({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  Pagination<T> copyWith({
    List<T>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return Pagination<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  bool get isFirstPage => page <= 1;

  int get nextPage => page + 1;
}
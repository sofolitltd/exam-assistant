/// State for an incrementally-loaded list backed by a limit/offset API.
///
/// Kept generic because the same load-more/refresh/cache shape is reused by
/// every screen that browses a paginated question list (mistakes practice,
/// subject questions, taxonomy question bank) — see [PagedNotifier].
class PagedState<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const PagedState({
    this.items = const [],
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  PagedState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

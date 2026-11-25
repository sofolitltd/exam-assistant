import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paginated_list.dart';
import 'paged_state.dart';

/// Base for a [Notifier] that incrementally loads a limit/offset-paginated
/// list and keeps already-fetched pages cached in memory for as long as the
/// provider stays alive (not `autoDispose`, so returning to a screen within
/// the same app session reuses the pages already loaded instead of
/// refetching from the start). Call [refresh] to force a reload, e.g. on
/// pull-to-refresh.
abstract class PagedNotifier<T> extends Notifier<PagedState<T>> {
  static const pageSize = 50;

  int _offset = 0;

  /// Fetches one page starting at [offset], at most [limit] items.
  Future<PaginatedList<T>> fetchPage(int limit, int offset);

  @override
  PagedState<T> build() {
    _offset = 0;
    Future.microtask(_loadFirstPage);
    return const PagedState();
  }

  Future<void> _loadFirstPage() async {
    try {
      final page = await fetchPage(pageSize, 0);
      _offset = page.items.length;
      state = PagedState(
        items: page.items,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (error) {
      state = PagedState(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await fetchPage(pageSize, _offset);
      _offset += page.items.length;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    state = const PagedState();
    await _loadFirstPage();
  }
}

/// Result of a paginated list endpoint shaped as `{"items": [...], "hasMore": bool}`.
class PaginatedList<T> {
  final List<T> items;
  final bool hasMore;

  const PaginatedList({required this.items, required this.hasMore});

  factory PaginatedList.fromJson(
    dynamic json,
    T Function(Map<String, dynamic> item) fromItem,
  ) {
    if (json is! Map) {
      throw const FormatException('Expected a paginated API response.');
    }
    final map = Map<String, dynamic>.from(json);
    final rawItems = map['items'];
    if (rawItems is! List) {
      throw const FormatException('Expected a paginated API response.');
    }
    return PaginatedList<T>(
      items: rawItems
          .map((item) => fromItem(Map<String, dynamic>.from(item as Map)))
          .toList(),
      hasMore: map['hasMore'] as bool? ?? false,
    );
  }
}

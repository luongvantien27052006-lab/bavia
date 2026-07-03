// lib/models/paginated.dart
//
// Wrapper cho response phân trang của backend:
//   { "items": [...], "pagination": { "limit": 50, "offset": 0, "count": 7 } }
// Lưu ý: backend dùng key "count" (không phải "total").

import 'json_x.dart';

class Paginated<T> {
  final List<T> items;
  final int limit;
  final int offset;
  final int count;

  const Paginated({
    required this.items,
    required this.limit,
    required this.offset,
    required this.count,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = JsonX.list(json, ['items', 'data']);
    final pg = JsonX.map(json, ['pagination', 'meta']) ?? const {};

    return Paginated<T>(
      items: rawItems
          .whereType<Map>()
          .map((e) => fromItem(Map<String, dynamic>.from(e)))
          .toList(),
      limit: JsonX.intVal(pg, ['limit'], fallback: rawItems.length),
      offset: JsonX.intVal(pg, ['offset']),
      count: JsonX.intVal(pg, ['count', 'total'], fallback: rawItems.length),
    );
  }

  bool get isEmpty => items.isEmpty;
}

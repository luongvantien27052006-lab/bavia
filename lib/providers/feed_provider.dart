// lib/providers/feed_provider.dart
// Feed thông báo trong app: tin tức, điểm danh, hoàn tiền (thành công/từ chối)...

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

class NotificationItem {
  final String id;
  final String type; // NEWS | CHECKIN | REFUND_DONE | REFUND_REJECTED | ORDER | SYSTEM
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool unread;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.data,
    required this.createdAt,
    required this.unread,
  });

  factory NotificationItem.fromJson(Map j) => NotificationItem(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? 'SYSTEM',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString(),
        data: j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : null,
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        unread: j['unread'] == true,
      );
}

class FeedNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() => _fetch();

  Future<List<NotificationItem>> _fetch() async {
    try {
      final raw = await ApiClient.I.get('/feed');
      final list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
      return list
          .map((e) => NotificationItem.fromJson(Map.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> refresh() async {
    state = AsyncData(await _fetch());
  }

  /// Đánh dấu đã đọc tất cả (gọi khi mở màn thông báo).
  Future<void> markRead() async {
    try {
      await ApiClient.I.post('/feed/read');
    } catch (_) {}
    await refresh();
    ref.invalidate(unreadCountProvider);
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<NotificationItem>>(
        FeedNotifier.new);

/// Số thông báo chưa đọc (badge chuông).
final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final raw = await ApiClient.I.get('/feed/unread-count');
    final m = (raw is Map && raw['data'] is Map)
        ? raw['data'] as Map
        : (raw as Map);
    return (m['count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/feed_provider.dart';
import '../../providers/menu_provider.dart';
import '../orders/order_detail_screen.dart';
import '../product/product_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mở màn -> đánh dấu đã đọc tất cả.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).markRead();
    });
  }

  ({IconData icon, Color color}) _style(String type) {
    switch (type) {
      case 'REFUND_DONE':
        return (icon: Icons.check_circle_rounded, color: AppColors.success);
      case 'REFUND_REJECTED':
        return (icon: Icons.cancel_rounded, color: AppColors.delivery);
      case 'REFUND_CONFIRM':
        return (
          icon: Icons.pending_actions_rounded,
          color: AppColors.delivery
        );
      case 'NEWS':
        return (icon: Icons.campaign_rounded, color: AppColors.coffee);
      case 'CHECKIN':
        return (icon: Icons.event_available_rounded, color: AppColors.coffee);
      case 'POINTS':
        return (icon: Icons.stars_rounded, color: AppColors.delivery);
      case 'NEW_PRODUCT':
        return (icon: Icons.fiber_new_rounded, color: AppColors.delivery);
      case 'ORDER':
        return (icon: Icons.receipt_long_rounded, color: AppColors.coffee);
      default:
        return (icon: Icons.notifications_rounded, color: AppColors.coffee);
    }
  }

  String _time(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  void _handleTap(String? orderId, String? productId) {
    if (orderId != null && orderId.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: orderId),
      ));
      return;
    }
    if (productId != null && productId.isNotEmpty) {
      final all = ref.read(productsProvider).valueOrNull;
      for (final x in (all ?? const [])) {
        if (x.id == productId) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: x),
          ));
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            children: const [
              SizedBox(height: 120),
              Center(child: Text('Không tải được thông báo')),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Chưa có thông báo nào',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                final s = _style(n.type);
                final orderId = n.data?['orderId']?.toString();
                final productId = n.data?['productId']?.toString();
                final tappable = (orderId != null && orderId.isNotEmpty) ||
                    (productId != null && productId.isNotEmpty);
                return GestureDetector(
                  onTap: tappable ? () => _handleTap(orderId, productId) : null,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: n.unread
                        ? Border.all(color: s.color.withOpacity(0.4))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.icon, color: s.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                if (n.unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin:
                                        const EdgeInsets.only(left: 6, top: 4),
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            if (n.body != null && n.body!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.body!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _time(n.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

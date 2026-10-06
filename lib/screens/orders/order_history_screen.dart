// lib/screens/orders/order_history_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Lịch sử đơn hàng của khách (GET /orders).
// Mỗi đơn là 1 thẻ kính: ảnh các món, trạng thái màu, thời gian, tổng tiền.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/anim.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/menu_image.dart';
import '../../widgets/stage.dart';
import 'order_detail_screen.dart';
import 'order_status_style.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final count = orders.valueOrNull?.length;

    return StageScaffold(
      title: 'Đơn hàng của tôi',
      subtitle: count != null && count > 0 ? '$count đơn' : null,
      tint: DrinkTint.fallback,
      body: orders.when(
        loading: () =>  Center(
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: St.fg(0.7))),
        error: (e, _) => _error(ref),
        data: (list) {
          Future<void> refresh() async => ref.invalidate(ordersProvider);
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              color: St.fg(),
              backgroundColor: St.refreshBg,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.receipt_long_outlined,
                      size: 56, color: St.fg(0.5)),
                  const SizedBox(height: 14),
                   Text('Chưa có đơn hàng nào',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: St.fg(),
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Các đơn bạn đặt sẽ hiện ở đây để theo dõi & đặt lại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: St.fg(0.65))),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            color: St.fg(),
            backgroundColor: St.refreshBg,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  FadeSlideIn(index: i, child: _orderCard(context, list[i])),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final c = order.status.color;
    final id = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final names = order.items
        .map((e) => e.productName.isEmpty ? 'Món đã ngừng bán' : e.productName)
        .toList();
    final thumbs = order.items.take(3).toList();
    final more = order.items.length - thumbs.length;

    return StageGlass(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('#${id.toUpperCase()}',
                    style:  TextStyle(
                        color: St.fg(),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              StageChip(label: order.status.label, icon: order.status.icon, color: c),
            ],
          ),
          const SizedBox(height: 2),
          Text(Formatters.dateTime(order.createdAt),
              style: TextStyle(
                  color: St.fg(0.55), fontSize: 12)),
          if (thumbs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final it in thumbs) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MenuImage(
                      url: it.imageUrl,
                      size: 44,
                      fallback: Container(
                        width: 44,
                        height: 44,
                        color: St.fill(0.08),
                        child: Icon(Icons.local_drink_rounded,
                            size: 20,
                            color: St.fg(0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (more > 0)
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: St.fill(0.10),
                    ),
                    child: Text('+$more',
                        style:  TextStyle(
                            color: St.fg(), fontWeight: FontWeight.w800)),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    names.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: St.fg(0.75),
                        fontSize: 12.5,
                        height: 1.3),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: St.line(0.08)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                  order.paymentMethod == PaymentMethodType.bankQr
                      ? Icons.qr_code_2_rounded
                      : Icons.payments_rounded,
                  size: 16,
                  color: St.fg(0.55)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(order.paymentMethod?.label ?? '',
                    style: TextStyle(
                        color: St.fg(0.6),
                        fontSize: 12.5)),
              ),
              Text(Formatters.money(order.finalAmount),
                  style:  TextStyle(
                      color: St.fg(),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  color: St.fg(0.6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _error(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: St.fg(0.5)),
            const SizedBox(height: 12),
            Text('Không tải được đơn hàng.\nKiểm tra mạng rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: St.fg(0.75))),
            const SizedBox(height: 16),
            StageButton(
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              expand: false,
              white: true,
              onTap: () => ref.invalidate(ordersProvider),
            ),
          ],
        ),
      ),
    );
  }
}

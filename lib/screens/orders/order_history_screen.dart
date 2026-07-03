// lib/screens/orders/order_history_screen.dart
//
// Lịch sử đơn hàng của khách. Lấy từ ordersProvider (GET /orders).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(ref, e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Chưa có đơn hàng nào',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _orderCard(context, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(Formatters.dateTime(order.createdAt),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.paymentMethod?.label ?? '',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                Text(Formatters.money(order.finalAmount),
                    style: const TextStyle(
                        color: AppColors.coffee,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    final color = switch (status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled || OrderStatus.refunded => AppColors.delivery,
      OrderStatus.pending => AppColors.hot,
      _ => AppColors.coffee,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _error(WidgetRef ref, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(ordersProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

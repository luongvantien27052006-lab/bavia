// lib/screens/orders/order_detail_screen.dart
//
// Chi tiết đơn + huỷ đơn (chỉ khi đang PENDING). Huỷ gọi POST /orders/:id/cancel.

import 'package:flutter/material.dart';
import 'order_status_style.dart';
import 'package:flutter/services.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/product_review_tile.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/repository_providers.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _cancelling = false;

  Future<void> _confirmCancel(OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ đơn hàng?'),
        content: const Text(
            'Đơn sẽ bị huỷ và hoàn lại voucher/điểm (nếu có). Bạn chắc chắn?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ đơn',
                style: TextStyle(color: AppColors.delivery)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(ordersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã huỷ đơn'),
              backgroundColor: AppColors.success),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.delivery),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _confirmReceived(OrderModel order) async {
    setState(() => _cancelling = true);
    try {
      HapticFeedback.mediumImpact();
      await ApiClient.I.post('/orders/${order.id}/received');
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(ordersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã xác nhận nhận hàng. Cảm ơn bạn! 🎉'),
              backgroundColor: AppColors.success),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.delivery),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: AppColors.delivery),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.orderId));

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
      appBar: AppBar(
        title: const Text('Chi tiết đơn',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được đơn: $e',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
        data: (order) => _content(order),
      ),
    ));
  }

  Widget _content(OrderModel order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statusHeader(order),
        const SizedBox(height: 16),
        _statusTracker(order),
        const SizedBox(height: 16),
        if (order.items.isNotEmpty) ...[
          const Text('Món đã đặt',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          ...order.items.map(_itemRow),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (order.discountAmount > 0)
                _row('Giảm giá', '−${Formatters.money(order.discountAmount)}'),
              _row('Tổng tiền', Formatters.money(order.finalAmount),
                  bold: true),
              if (order.pointsEarned > 0)
                _row('Điểm tích luỹ', '+${order.pointsEarned}',
                    highlight: true),
              _row('Thanh toán', order.paymentMethod?.label ?? '—'),
              _row('Trạng thái TT', order.paymentStatus.label),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ratingSection(order),
        if (order.status == OrderStatus.delivering) ...[
          ElevatedButton.icon(
            onPressed: _cancelling ? null : () => _confirmReceived(order),
            icon: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Đã nhận hàng'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (order.status.isCancellable)
          OutlinedButton.icon(
            onPressed: _cancelling ? null : () => _confirmCancel(order),
            icon: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cancel_outlined, color: AppColors.delivery),
            label: const Text('Huỷ đơn hàng',
                style: TextStyle(color: AppColors.delivery)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.delivery),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
      ],
    );
  }

  /// #3 Đánh giá món — chỉ hiện khi đơn ĐÃ GIAO.
  Widget _ratingSection(OrderModel order) {
    if (order.status != OrderStatus.delivered || order.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF5A623)),
              const SizedBox(width: 8),
              Text('Đánh giá món',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Cảm ơn bạn! Đánh giá giúp quán phục vụ tốt hơn.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          for (final it in order.items)
            ProductReviewTile(
              productId: it.productId,
              productName: it.productName,
              orderId: order.id,
            ),
        ],
      ),
    );
  }

  Widget _statusHeader(OrderModel order) {
    final c = order.status.color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.24)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: c.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(order.status.icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(order.status.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Mã đơn #${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 13)),
          const SizedBox(height: 2),
          Text(Formatters.dateTime(order.createdAt),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Thanh tiến trình theo dõi đơn ───────────────────────────────────

  /// Quy ước "chặng": pending=0, confirmed=1, in_progress=2, ready=3,
  /// delivered=4; cancelled/refunded/unknown=-1.
  int _stageOf(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.inProgress:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.delivering:
        return 4;
      case OrderStatus.delivered:
        return 5;
      default:
        return -1;
    }
  }

  Widget _statusTracker(OrderModel order) {
    // Đơn huỷ / hoàn tiền: băng riêng, không hiện tiến trình.
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.refunded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.delivery.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.delivery.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.delivery),
            const SizedBox(width: 10),
            Text(order.status.label,
                style: const TextStyle(
                    color: AppColors.delivery, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    final stage = _stageOf(order.status);
    final steps = <({String label, IconData icon})>[
      (label: 'Đã xác nhận', icon: Icons.receipt_long_rounded),
      (label: 'Đang pha chế', icon: Icons.local_cafe_rounded),
      (label: 'Sẵn sàng', icon: Icons.shopping_bag_rounded),
      (label: 'Đang giao', icon: Icons.delivery_dining_rounded),
      (label: 'Hoàn thành', icon: Icons.check_circle_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tiến trình ngang tổng quan.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0, end: (stage / 5).clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.dark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.06),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.coffee),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (stage == 0) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.coffee),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Đang chờ quán xác nhận…',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          for (int i = 0; i < steps.length; i++)
            _trackerStep(
              label: steps[i].label,
              icon: steps[i].icon,
              stepStage: i + 1,
              currentStage: stage,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _trackerStep({
    required String label,
    required IconData icon,
    required int stepStage,
    required int currentStage,
    required bool isLast,
  }) {
    final bool done =
        currentStage > stepStage || (isLast && currentStage >= stepStage);
    final bool current = !done && currentStage == stepStage;
    final bool reached = currentStage >= stepStage;

    final Color color = done
        ? AppColors.success
        : current
            ? AppColors.coffee
            : AppColors.textMuted.withOpacity(0.35);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: reached ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  done ? Icons.check_rounded : icon,
                  size: 18,
                  color: reached ? Colors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: currentStage > stepStage
                        ? AppColors.success
                        : AppColors.textMuted.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 18),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: reached ? AppColors.textDark : AppColors.textMuted,
                fontSize: current ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.coffee.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${item.quantity}',
                style: const TextStyle(
                    color: AppColors.coffee, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                item.productName.isEmpty ? 'Sản phẩm' : item.productName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(Formatters.money(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? AppColors.textDark : AppColors.textMuted,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: bold ? 16 : 14,
                  color: highlight
                      ? AppColors.success
                      : (bold ? AppColors.coffee : AppColors.textDark))),
        ],
      ),
    );
  }
}
// lib/screens/checkout/order_success_screen.dart
//
// Màn xác nhận đặt đơn thành công. [paid] = true khi đã nhận thanh toán QR.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../utils/formatters.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  final bool paid;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.paid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 72),
              ),
              const SizedBox(height: 24),
              Text(
                paid ? 'Thanh toán thành công!' : 'Đặt hàng thành công!',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                paid
                    ? 'Cảm ơn bạn! Đơn hàng đang được chuẩn bị.'
                    : 'Đơn của bạn đã được tiếp nhận.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              _detailCard(),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54)),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _row('Mã đơn', '#${order.id.substring(0, 8).toUpperCase()}'),
          const Divider(height: 18),
          _row('Tổng tiền', Formatters.money(order.finalAmount)),
          if (order.pointsEarned > 0) ...[
            const Divider(height: 18),
            _row('Điểm tích luỹ', '+${order.pointsEarned} điểm',
                highlight: true),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.success : AppColors.textDark)),
      ],
    );
  }
}

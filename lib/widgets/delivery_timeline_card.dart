// ============================================================
//  FLUTTER — lib/widgets/delivery_timeline_card.dart  (MỚI)
//  Thanh timeline giao hàng (Kiểu A) hiện ở Home khi có đơn đang xử lý.
//  Tự cập nhật realtime qua ordersProvider (socket invalidate).
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/order_model.dart';
import 'glass_card.dart';

class DeliveryTimelineCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  const DeliveryTimelineCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  static const List<({String label, IconData icon})> _steps = [
    (label: 'Xác nhận', icon: Icons.receipt_long_rounded),
    (label: 'Đang pha', icon: Icons.local_cafe_rounded),
    (label: 'Sẵn sàng', icon: Icons.shopping_bag_rounded),
    (label: 'Đang giao', icon: Icons.delivery_dining_rounded),
    (label: 'Đã nhận', icon: Icons.home_rounded),
  ];

  int get _stage {
    switch (order.status) {
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
        return 0;
    }
  }

  String get _title {
    switch (order.status) {
      case OrderStatus.delivering:
        return '🛵 Đơn đang giao';
      case OrderStatus.ready:
        return '🎉 Đơn đã sẵn sàng';
      case OrderStatus.inProgress:
        return '☕ Đang pha chế';
      case OrderStatus.confirmed:
        return '✅ Cửa hàng đã nhận đơn';
      default:
        return 'Đơn của bạn';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    final fillPct = ((stage - 1) / (_steps.length - 1)).clamp(0.0, 1.0);

    return GlassCard(
      blur: 12,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coffee.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order.status.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coffee)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 54,
                child: Stack(
                  children: [
                    // đường nền
                    Positioned(
                      left: w * 0.1,
                      right: w * 0.1,
                      top: 15,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.dark
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFFECE3DB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // đường tô (tiến độ)
                    Positioned(
                      left: w * 0.1,
                      top: 15,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: 3,
                        width: (w * 0.8) * fillPct,
                        decoration: BoxDecoration(
                          color: AppColors.coffee,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // các bước
                    Row(
                      children: [
                        for (int i = 0; i < _steps.length; i++)
                          Expanded(child: _stepView(i, stage)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stepView(int i, int stage) {
    final done = i < stage; // bước đã xong (stage 1 -> index 0)
    final active = i == stage - 1; // bước hiện tại
    final color = AppColors.coffee;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? color
                : (AppColors.dark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFECE3DB)),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 0,
                        spreadRadius: 4)
                  ]
                : (done
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : null),
          ),
          child: Icon(
            done && !active ? Icons.check_rounded : _steps[i].icon,
            size: 15,
            color: done ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(_steps[i].label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: done ? AppColors.textDark : AppColors.textMuted)),
      ],
    );
  }
}
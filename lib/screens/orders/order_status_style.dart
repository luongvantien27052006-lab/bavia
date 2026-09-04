// lib/screens/orders/order_status_style.dart
//
// Màu + icon theo trạng thái đơn — NGUỒN DUY NHẤT cho toàn app.
// Giúp mọi màn (lịch sử đơn, chi tiết đơn, phòng nhóm...) hiển thị NHẤT QUÁN
// và phân biệt rõ từng trạng thái.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';

const _blue = Color(0xFF3B82F6);

extension OrderStatusStyle on OrderStatus {
  Color get color => switch (this) {
        OrderStatus.pending => AppColors.hot,
        OrderStatus.confirmed => _blue,
        OrderStatus.inProgress => AppColors.coffee,
        OrderStatus.ready => AppColors.pickup,
        OrderStatus.delivering => _blue,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.delivery,
        OrderStatus.refunded => AppColors.delivery,
        OrderStatus.unknown => AppColors.textMuted,
      };

  IconData get icon => switch (this) {
        OrderStatus.pending => Icons.hourglass_top_rounded,
        OrderStatus.confirmed => Icons.verified_rounded,
        OrderStatus.inProgress => Icons.local_cafe_rounded,
        OrderStatus.ready => Icons.shopping_bag_rounded,
        OrderStatus.delivering => Icons.delivery_dining_rounded,
        OrderStatus.delivered => Icons.check_circle_rounded,
        OrderStatus.cancelled => Icons.cancel_rounded,
        OrderStatus.refunded => Icons.replay_rounded,
        OrderStatus.unknown => Icons.help_outline_rounded,
      };
}
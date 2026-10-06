// lib/screens/checkout/order_success_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Màn xác nhận đặt đơn thành công.
// [paid] = true khi đã nhận thanh toán QR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/order_model.dart';
import '../../utils/formatters.dart';
import '../../widgets/anim.dart';
import '../../widgets/aurora_background.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/stage.dart';
import '../orders/order_detail_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  final bool paid;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.paid = false,
  });

  static const _green = Color(0xFF34C77B);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: stageOverlay,
      child: Scaffold(
        backgroundColor: DrinkTint.stageInk,
        body: AuroraBackground(
          tint: _green,
          base: DrinkTint.stageInk,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  const Spacer(),
                  const SuccessCheck(size: 110),
                  const SizedBox(height: 20),
                  Text(
                    paid ? 'Thanh toán thành công!' : 'Đặt hàng thành công!',
                    textAlign: TextAlign.center,
                    style:  TextStyle(
                        color: St.fg(),
                        fontSize: 26,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scheduledLabel != null
                        ? 'Cảm ơn bạn! Đơn hẹn nhận lúc $_scheduledLabel.\n'
                            'Quán sẽ chuẩn bị trước giờ hẹn.'
                        : paid
                            ? 'Cảm ơn bạn! Đơn hàng đang được chuẩn bị.'
                            : 'Đơn của bạn đã được tiếp nhận.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: St.fg(0.75),
                        height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _detailCard(),
                  const Spacer(),
                  StageButton(
                    label: 'Theo dõi đơn hàng',
                    icon: Icons.receipt_long_rounded,
                    white: true,
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.popUntil((route) => route.isFirst);
                      nav.push(MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id)));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: Text('Về trang chủ',
                        style: TextStyle(
                            color: St.fg(0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "16:00, 02/10" nếu là đơn hẹn giờ, ngược lại null.
  String? get _scheduledLabel {
    final t = order.scheduledFor;
    if (t == null) return null;
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}, ${two(l.day)}/${two(l.month)}';
  }

  Widget _detailCard() {
    final id = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    Widget div() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: St.line(0.1)),
        );
    return StageGlass(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _row('Mã đơn', '#${id.toUpperCase()}'),
          if (_scheduledLabel != null) ...[
            div(),
            _row('Giờ hẹn nhận', _scheduledLabel!),
          ],
          div(),
          _row('Tổng tiền', Formatters.money(order.finalAmount)),
          if (order.pointsEarned > 0) ...[
            div(),
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
        Text(label, style: TextStyle(color: St.fg(0.65))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: highlight ? const Color(0xFF4ADE80) : St.fg())),
      ],
    );
  }
}

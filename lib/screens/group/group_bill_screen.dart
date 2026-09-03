// lib/screens/group/group_bill_screen.dart
//
// Bảng kê chia tiền đơn nhóm: mỗi người trả bao nhiêu (tiền món − giảm + ship).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/group_order.dart';
import '../../providers/group_order_provider.dart';
import '../../utils/formatters.dart';

class GroupBillScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupBillScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupBillScreen> createState() => _GroupBillScreenState();
}

class _GroupBillScreenState extends ConsumerState<GroupBillScreen> {
  late Future<GroupBill> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(groupOrderRepositoryProvider).getBill(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Chia tiền'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: FutureBuilder<GroupBill>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Text('Không tải được bảng kê',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return _content(snap.data!);
        },
      ),
    );
  }

  Widget _content(GroupBill bill) {
    final hostPays = bill.paymentMode == 'HOST_PAYS';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hostPays
                ? AppColors.coffee.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (hostPays ? AppColors.coffee : AppColors.success)
                    .withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(hostPays ? Icons.account_balance_wallet_rounded : Icons.groups_rounded,
                  color: hostPays ? AppColors.coffee : AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    hostPays
                        ? 'Chủ phòng trả toàn bộ — đây là số tiền cần THU LẠI từ mỗi người.'
                        : 'Mỗi người tự trả phần của mình.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textDark, height: 1.4)),
              ),
            ],
          ),
        ),
        if (bill.preview) ...[
          const SizedBox(height: 10),
          Text('* Tạm tính (chưa gồm phí ship / giảm giá — sẽ cập nhật sau khi chốt).',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
        const SizedBox(height: 16),
        ...bill.shares.map((sh) => _shareCard(sh, hostPays)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _totalRow('Tổng tiền món', bill.subtotal),
              if (bill.itemDiscount > 0)
                _totalRow('Giảm giá', -bill.itemDiscount,
                    color: AppColors.success),
              if (bill.shippingFee > 0)
                _totalRow('Phí giao hàng', bill.shippingFee),
              const Divider(height: 20),
              _totalRow('Tổng cộng', bill.grandTotal, bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shareCard(BillShare sh, bool hostPays) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.coffee.withOpacity(0.15),
                child: Text(
                    (sh.name.isNotEmpty ? sh.name[0] : '?').toUpperCase(),
                    style: TextStyle(
                        color: AppColors.coffee,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(sh.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ),
              Text(Formatters.money(sh.finalShare),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: hostPays ? AppColors.coffee : AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          _miniRow('Tiền món', Formatters.money(sh.itemsSubtotal)),
          if (sh.discountShare > 0)
            _miniRow('Giảm giá', '−${Formatters.money(sh.discountShare)}',
                color: AppColors.success),
          if (sh.shippingShare > 0)
            _miniRow('Phí ship', '+${Formatters.money(sh.shippingShare)}'),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            Text(value,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textDark)),
          ],
        ),
      );

  Widget _totalRow(String label, int value,
          {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 16 : 13.5,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: bold ? AppColors.textDark : AppColors.textMuted)),
            Text(
                '${value < 0 ? '−' : ''}${Formatters.money(value.abs())}',
                style: TextStyle(
                    fontSize: bold ? 18 : 14,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                    color: color ?? AppColors.textDark)),
          ],
        ),
      );
}
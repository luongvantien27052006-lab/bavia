// lib/screens/group/group_voucher_select_screen.dart
//
// Chọn voucher cho ĐƠN NHÓM — bản song sinh của voucher_select_screen (checkout
// thường), nhưng:
//  - Lọc điều kiện theo TỔNG TIỀN PHÒNG (truyền vào), không phải giỏ cá nhân.
//  - Không đụng checkoutProvider; chỉ TRẢ VỀ mã đã chọn qua Navigator.pop.
//    Backend group checkout/collect sẽ tự validate lại server-side.
//
// Trả về: GroupVoucherPick(discountCode, shippingCode) — null nếu bỏ chọn.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/voucher_wallet.dart';
import '../../providers/voucher_wallet_provider.dart';
import '../../utils/formatters.dart';

/// Kết quả chọn voucher cho phòng.
class GroupVoucherPick {
  final String? discountCode;
  final String? shippingCode;
  const GroupVoucherPick({this.discountCode, this.shippingCode});
}

class GroupVoucherSelectScreen extends ConsumerStatefulWidget {
  /// Tổng tiền món của phòng (để xét voucher đủ/không đủ điều kiện).
  final int groupSubtotal;
  final String? initialDiscountCode;
  final String? initialShippingCode;

  const GroupVoucherSelectScreen({
    super.key,
    required this.groupSubtotal,
    this.initialDiscountCode,
    this.initialShippingCode,
  });

  @override
  ConsumerState<GroupVoucherSelectScreen> createState() =>
      _GroupVoucherSelectScreenState();
}

class _GroupVoucherSelectScreenState
    extends ConsumerState<GroupVoucherSelectScreen> {
  final _codeCtrl = TextEditingController();
  String? _selDiscount;
  String? _selShipping;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _selDiscount = widget.initialDiscountCode;
    _selShipping = widget.initialShippingCode;
    _codeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  int get _subtotal => widget.groupSubtotal;

  int _eff(VoucherWallet v) => v.isPercent
      ? (_subtotal * v.discountValue / 100).round()
      : v.discountValue;

  bool _eligible(VoucherWallet v) => v.isUsable && _subtotal >= v.minOrderValue;

  void _done() {
    Navigator.pop(
      context,
      GroupVoucherPick(discountCode: _selDiscount, shippingCode: _selShipping),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(availableVouchersProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Chọn voucher',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Ô nhập mã thủ công + nút "Chọn" (thêm vào lựa chọn, chưa validate).
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.textDark),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Nhập mã voucher',
                          hintStyle: TextStyle(
                              color: AppColors.textMuted, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _codeCtrl.text.trim().isEmpty
                        ? null
                        : () {
                            // Mã gõ tay coi là mã giảm giá; backend sẽ validate
                            // khi chốt đơn. (Không rõ freeship hay giảm giá nên
                            // mặc định là giảm giá.)
                            setState(() {
                              _selDiscount =
                                  _codeCtrl.text.trim().toUpperCase();
                              _codeCtrl.clear();
                            });
                          },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _codeCtrl.text.trim().isEmpty
                            ? const Color(0xFFCFCFCF)
                            : AppColors.coffee,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8)),
                      ),
                      child: const Text('Chọn',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Không tải được voucher',
                      style: TextStyle(color: AppColors.textMuted))),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                      child: Text('Bạn chưa có voucher nào',
                          style: TextStyle(color: AppColors.textMuted)));
                }
                final shipping =
                    list.where((v) => v.type == 'SHIPPING').toList();
                final discount =
                    list.where((v) => v.type != 'SHIPPING').toList();
                shipping.sort((a, b) => _eff(b).compareTo(_eff(a)));
                discount.sort((a, b) => _eff(b).compareTo(_eff(a)));

                if (!_init) {
                  _init = true;
                  // Chỉ auto-chọn nếu chưa có lựa chọn ban đầu.
                  if (_selDiscount == null) {
                    for (final v in discount) {
                      if (_eligible(v)) {
                        _selDiscount = v.code;
                        break;
                      }
                    }
                  }
                  if (_selShipping == null) {
                    for (final v in shipping) {
                      if (_eligible(v)) {
                        _selShipping = v.code;
                        break;
                      }
                    }
                  }
                }

                String? bestShip;
                for (final v in shipping) {
                  if (_eligible(v)) {
                    bestShip = v.code;
                    break;
                  }
                }
                String? bestDisc;
                for (final v in discount) {
                  if (_eligible(v)) {
                    bestDisc = v.code;
                    break;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    if (shipping.isNotEmpty) ...[
                      _sectionLabel('Ưu đãi phí vận chuyển'),
                      ...shipping.map((v) => _card(v,
                          isShipping: true, isBest: v.code == bestShip)),
                      const SizedBox(height: 8),
                    ],
                    if (discount.isNotEmpty) ...[
                      _sectionLabel('Mã giảm giá'),
                      ...discount.map((v) => _card(v,
                          isShipping: false, isBest: v.code == bestDisc)),
                    ],
                  ],
                );
              },
            ),
          ),

          _bottomBar(),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final count =
        (_selDiscount != null ? 1 : 0) + (_selShipping != null ? 1 : 0);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count > 0 ? '$count voucher đã chọn' : 'Chưa chọn voucher nào',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
            ),
            SizedBox(
              height: 48,
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _done,
                child: const Text('Đồng ý',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
      );

  Widget _card(VoucherWallet v,
      {required bool isShipping, required bool isBest}) {
    final meetsMin = _subtotal >= v.minOrderValue;
    final eligible = v.isUsable && meetsMin;
    final selected =
        isShipping ? _selShipping == v.code : _selDiscount == v.code;
    final accent = isShipping ? AppColors.success : AppColors.coffee;

    String? reason;
    if (v.isExpired) {
      reason = 'Đã hết hạn';
    } else if (v.remainingForMe <= 0) {
      reason = 'Đã hết lượt dùng';
    } else if (!meetsMin) {
      reason = 'Cần đơn tối thiểu ${Formatters.money(v.minOrderValue)}';
    }

    final discountLabel = v.isPercent
        ? 'Giảm ${v.discountValue}%'
        : isShipping
            ? 'Giảm ship ${Formatters.money(v.discountValue)}'
            : 'Giảm ${Formatters.money(v.discountValue)}';

    return Opacity(
      opacity: eligible ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: eligible
              ? () => setState(() {
                    if (isShipping) {
                      _selShipping = selected ? null : v.code;
                    } else {
                      _selDiscount = selected ? null : v.code;
                    }
                  })
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 96,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(11)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isShipping
                                ? Icons.local_shipping_rounded
                                : Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 26),
                        const SizedBox(height: 4),
                        Text(isShipping ? 'FREESHIP' : 'GIẢM GIÁ',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isBest)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.hot.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text('Lựa chọn tốt nhất',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.hot)),
                            ),
                          Text(discountLabel,
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(v.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                          if (v.minOrderValue > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                  'Đơn tối thiểu ${Formatters.money(v.minOrderValue)}',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted)),
                            ),
                          if (reason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(reason,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.delivery)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : eligible
                                  ? Icons.radio_button_unchecked_rounded
                                  : Icons.lock_rounded,
                          color: selected
                              ? accent
                              : eligible
                                  ? AppColors.textMuted
                                  : AppColors.textMuted.withOpacity(0.6),
                          size: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

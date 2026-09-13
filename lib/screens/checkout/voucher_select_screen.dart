// lib/screens/checkout/voucher_select_screen.dart
//
// Trang chọn voucher (full màn hình) theo phong cách Shopee:
//  - Ô nhập mã + nút Áp dụng ở trên đầu (luôn hoạt động).
//  - Tách 2 nhóm: "Ưu đãi phí vận chuyển" (freeship) và "Mã giảm giá".
//  - Voucher đủ điều kiện: sáng, tích được; không đủ: mờ + khoá + lý do.
//  - Tự tích voucher giảm nhiều nhất mỗi nhóm; "Đồng ý" áp dụng + thoát.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/voucher_wallet_provider.dart';
import '../../models/voucher_wallet.dart';
import '../../utils/formatters.dart';

class VoucherSelectScreen extends ConsumerStatefulWidget {
  const VoucherSelectScreen({super.key});
  @override
  ConsumerState<VoucherSelectScreen> createState() =>
      _VoucherSelectScreenState();
}

class _VoucherSelectScreenState extends ConsumerState<VoucherSelectScreen> {
  final _codeCtrl = TextEditingController();
  String? _selDiscount; // code voucher giảm giá đang chọn
  String? _selShipping; // code voucher freeship đang chọn
  bool _init = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  int _eff(VoucherWallet v, int subtotal) => v.isPercent
      ? (subtotal * v.discountValue / 100).round()
      : v.discountValue;

  bool _eligible(VoucherWallet v, int subtotal) =>
      v.isUsable && subtotal >= v.minOrderValue;

  Future<void> _applyAndClose(CheckoutState checkout) async {
    final n = ref.read(checkoutProvider.notifier);
    if (_selDiscount != checkout.appliedCode) {
      if (_selDiscount != null) {
        await n.applyVoucher(_selDiscount!);
      } else {
        n.removeVoucher();
      }
    }
    if (_selShipping != checkout.shippingCode) {
      if (_selShipping != null) {
        await n.applyVoucher(_selShipping!);
      } else {
        n.removeShippingVoucher();
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
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
          // ─── Ô nhập mã + nút Áp dụng (kiểu Shopee) ───
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã voucher',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.dark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF5F5F5),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.coffee, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: checkout.validatingVoucher
                        ? null
                        : () async {
                            final code = _codeCtrl.text.trim();
                            if (code.isEmpty) return;
                            await ref
                                .read(checkoutProvider.notifier)
                                .applyVoucher(code);
                            if (mounted) Navigator.pop(context);
                          },
                    child: checkout.validatingVoucher
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Áp dụng',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
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
                // Giảm nhiều hơn lên trước.
                shipping.sort(
                    (a, b) => _eff(b, subtotal).compareTo(_eff(a, subtotal)));
                discount.sort(
                    (a, b) => _eff(b, subtotal).compareTo(_eff(a, subtotal)));

                // Lần đầu mở: tự chọn voucher đủ ĐK giảm nhiều nhất mỗi nhóm.
                if (!_init) {
                  _init = true;
                  VoucherWallet? bestD;
                  for (final v in discount) {
                    if (_eligible(v, subtotal)) {
                      bestD = v;
                      break;
                    }
                  }
                  VoucherWallet? bestS;
                  for (final v in shipping) {
                    if (_eligible(v, subtotal)) {
                      bestS = v;
                      break;
                    }
                  }
                  _selDiscount = checkout.appliedCode ?? bestD?.code;
                  _selShipping = checkout.shippingCode ?? bestS?.code;
                }

                // id của voucher "tốt nhất" mỗi nhóm (đủ ĐK, giảm nhiều nhất).
                String? bestShipCode;
                for (final v in shipping) {
                  if (_eligible(v, subtotal)) {
                    bestShipCode = v.code;
                    break;
                  }
                }
                String? bestDiscCode;
                for (final v in discount) {
                  if (_eligible(v, subtotal)) {
                    bestDiscCode = v.code;
                    break;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    if (shipping.isNotEmpty) ...[
                      _sectionLabel('Ưu đãi phí vận chuyển'),
                      ...shipping.map((v) => _card(v, subtotal,
                          isShipping: true, isBest: v.code == bestShipCode)),
                      const SizedBox(height: 8),
                    ],
                    if (discount.isNotEmpty) ...[
                      _sectionLabel('Mã giảm giá'),
                      ...discount.map((v) => _card(v, subtotal,
                          isShipping: false, isBest: v.code == bestDiscCode)),
                    ],
                  ],
                );
              },
            ),
          ),

          // ─── Thanh dưới: tóm tắt + nút Đồng ý ───
          _bottomBar(checkout),
        ],
      ),
    );
  }

  Widget _bottomBar(CheckoutState checkout) {
    final count = (_selDiscount != null ? 1 : 0) + (_selShipping != null ? 1 : 0);
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
                count > 0
                    ? '$count voucher đã chọn'
                    : 'Chưa chọn voucher nào',
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
                onPressed: checkout.validatingVoucher
                    ? null
                    : () => _applyAndClose(checkout),
                child: const Text('Đồng ý',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
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

  Widget _card(VoucherWallet v, int subtotal,
      {required bool isShipping, required bool isBest}) {
    final meetsMin = subtotal >= v.minOrderValue;
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
                  // Ô màu bên trái (kiểu tem voucher).
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
                  // Nội dung.
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
                  // Tích chọn.
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
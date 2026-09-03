// ============================================================
//  FLUTTER
//  lib/screens/checkout/checkout_screen.dart
//  >> CHEP DE (phi ship + dia chi quan o muc chuyen khoan)
// ============================================================

// ==================================================================
//  FLUTTER — app khach (package bavia)
//  Dat tai:  lib/screens/checkout/checkout_screen.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/screens/checkout/checkout_screen.dart
//
// Đặt đơn: hình thức nhận hàng (Giao hàng/Tự lấy) + địa chỉ giao + phương thức
// thanh toán + dùng điểm + voucher → POST /orders.
// BANK_QR → màn QR; COD → màn thành công.

import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/loyalty_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/address_model.dart';
import '../../models/order_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/voucher_wallet_provider.dart';
import '../../models/voucher_wallet.dart';
import '../../providers/shipping_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/formatters.dart';
import '../address/address_form_screen.dart';
import 'order_success_screen.dart';
import 'qr_payment_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _addressInitialized = false;
  final _voucherController = TextEditingController();

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(checkoutDiscountProvider);
    final pointsDiscount = ref.watch(checkoutPointsDiscountProvider);
    final placing = ref.watch(placeOrderControllerProvider).isLoading;

    // Phí giao hàng theo khoảng cách (hỏi backend). Chỉ áp dụng khi giao hàng.
    final addr = checkout.deliveryAddress;
    final shipAsync = ref.watch(shippingQuoteProvider(ShipCoords(
      checkout.isDelivery ? addr?.latitude : null,
      checkout.isDelivery ? addr?.longitude : null,
      address: checkout.isDelivery ? addr?.detailedAddress : null,
    )));
    final ship = shipAsync.asData?.value;
    final shipFee = checkout.isDelivery ? (ship?.fee ?? 0) : 0;
    // Chồng voucher: 'discount' (mã giảm giá món) + 'shippingVoucher' (freeship).
    final itemDiscount = discount;
    final rawShipDiscount =
        checkout.hasShippingVoucher ? checkout.shippingVoucher!.discount : 0;
    final shipDiscount = rawShipDiscount < shipFee ? rawShipDiscount : shipFee;
    final grandTotalRaw =
        subtotal - itemDiscount - pointsDiscount + (shipFee - shipDiscount);
    final grandTotal = grandTotalRaw < 0 ? 0 : grandTotalRaw;

    // Chọn sẵn địa chỉ mặc định lần đầu (khi giao hàng).
    final addresses = ref.watch(addressesProvider);
    addresses.whenData((list) {
      if (!_addressInitialized &&
          checkout.isDelivery &&
          checkout.deliveryAddress == null &&
          list.isNotEmpty) {
        _addressInitialized = true;
        final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(checkoutProvider.notifier).setDeliveryAddress(def);
        });
      }
    });

    // Hiện lỗi voucher (nếu áp mã không hợp lệ).
    ref.listen(checkoutProvider, (prev, next) {
      if (next.voucherError != null &&
          next.voucherError != prev?.voucherError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.voucherError!),
              backgroundColor: AppColors.delivery),
        );
      }
    });

    // Điều hướng khi đặt đơn xong / báo lỗi.
    ref.listen(placeOrderControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          if (result.payment != null) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => QrPaymentScreen(result: result)));
          } else {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => OrderSuccessScreen(order: result.order)));
          }
        },
        error: (e, _) {
          final msg = e is ApiException ? e.message : e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.delivery),
          );
        },
      );
    });

    // Trạng thái mở/đóng cửa — mặc định coi như mở nếu đang tải/lỗi
    // (backend vẫn chặn chắc chắn ở phía server).
    final storeStatus = ref.watch(storeStatusProvider);
    final isOpen =
        storeStatus.maybeWhen(data: (s) => s.isOpen, orElse: () => true);
    final closedReason = storeStatus.maybeWhen(
        data: (s) => s.isOpen ? null : s.closedReason, orElse: () => null);

    final canPlace = !placing &&
        isOpen &&
        !(checkout.isDelivery && checkout.deliveryAddress == null);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
      appBar: AppBar(
        title: const Text('Thanh toán',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isOpen) ...[
            _closedBanner(closedReason ?? 'Quán đang đóng cửa'),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Hình thức nhận hàng'),
          const SizedBox(height: 10),
          _fulfillmentToggle(checkout.fulfillment),
          const SizedBox(height: 20),
          if (checkout.isDelivery) ...[
            _sectionTitle('Địa chỉ giao hàng'),
            const SizedBox(height: 10),
            _addressSection(checkout.deliveryAddress),
            const SizedBox(height: 20),
          ],
          _sectionTitle('Giờ nhận'),
          const SizedBox(height: 10),
          _scheduleSection(checkout),
          const SizedBox(height: 20),
          _sectionTitle('Phương thức thanh toán'),
          const SizedBox(height: 10),
          _paymentOption(
            method: PaymentMethodType.cod,
            selected: checkout.paymentMethod == PaymentMethodType.cod,
            icon: Icons.payments_rounded,
            title: 'Tiền mặt khi nhận hàng',
            subtitle: 'Thanh toán khi nhận món',
          ),
          const SizedBox(height: 10),
          _paymentOption(
            method: PaymentMethodType.bankQr,
            selected: checkout.paymentMethod == PaymentMethodType.bankQr,
            icon: Icons.qr_code_2_rounded,
            title: 'Chuyển khoản QR',
            subtitle: 'Quét VietQR, tự xác nhận khi nhận tiền',
          ),
          if (checkout.paymentMethod == PaymentMethodType.bankQr) ...[
            const SizedBox(height: 10),
            _bankNote(),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Mã giảm giá'),
          const SizedBox(height: 10),
          _voucherSection(checkout),
          const SizedBox(height: 20),
          _sectionTitle('Dùng điểm thưởng'),
          const SizedBox(height: 10),
          _pointsSection(subtotal),
          const SizedBox(height: 20),
          _summaryCard(subtotal, itemDiscount, pointsDiscount, grandTotal,
              shipFee, ship, checkout.isDelivery, shipDiscount),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: canPlace
                ? () => ref
                    .read(placeOrderControllerProvider.notifier)
                    .placeOrder()
                : null,
            child: placing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(isOpen
                    ? 'Đặt hàng • ${Formatters.money(grandTotal)}'
                    : 'Quán đang đóng cửa'),
          ),
        ),
      ),
    ));
  }

  String _fmtSchedule(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)} ${two(dt.day)}/${two(dt.month)}';
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(minutes: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isAfter(now) ? base : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(now)) {
      return now.add(const Duration(minutes: 15));
    }
    return picked;
  }

  Widget _scheduleOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.coffee.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.coffee : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.coffee : AppColors.textDark)),
        ),
      ),
    );
  }

  Widget _scheduleSection(CheckoutState checkout) {
    final scheduled = checkout.scheduledFor;
    Future<void> pick() async {
      final picked = await _pickDateTime(scheduled);
      if (picked != null) {
        ref.read(checkoutProvider.notifier).setScheduledFor(picked);
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _scheduleOption('Giao ngay', scheduled == null, () {
                ref.read(checkoutProvider.notifier).setScheduledFor(null);
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _scheduleOption('Hẹn giờ', scheduled != null, pick),
            ),
          ],
        ),
        if (scheduled != null) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: pick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.coffee.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.coffee.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: AppColors.coffee, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Nhận lúc ${_fmtSchedule(scheduled)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ),
                  Text('Đổi',
                      style: TextStyle(
                          color: AppColors.coffee,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));

  // ─── Băng "đóng cửa" ─────────────────────────────────────────────────
  Widget _closedBanner(String reason) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.delivery.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.delivery.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.do_not_disturb_on_rounded,
                color: AppColors.delivery),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quán đang đóng cửa',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.delivery)),
                  const SizedBox(height: 2),
                  Text(reason,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Hình thức nhận hàng ─────────────────────────────────────────────
  Widget _fulfillmentToggle(FulfillmentType current) {
    Widget opt(FulfillmentType type, IconData icon, Color color) {
      final selected = current == type;
      return Expanded(
        child: GestureDetector(
          onTap: () =>
              ref.read(checkoutProvider.notifier).setFulfillment(type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : const Color(0xFFE5DDD7),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    color: selected ? color : AppColors.textMuted, size: 28),
                const SizedBox(height: 6),
                Text(type.label,
                    style: TextStyle(
                        color: selected ? color : AppColors.textDark,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opt(FulfillmentType.delivery, Icons.delivery_dining_rounded,
            AppColors.delivery),
        const SizedBox(width: 12),
        opt(FulfillmentType.pickup, Icons.storefront_rounded,
            AppColors.pickup),
      ],
    );
  }

  // ─── Địa chỉ giao hàng ───────────────────────────────────────────────
  Widget _addressSection(AddressModel? selected) {
    if (selected == null) {
      return GestureDetector(
        onTap: _openAddressPicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.delivery.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: AppColors.delivery),
              SizedBox(width: 12),
              Expanded(
                child: Text('Chọn hoặc thêm địa chỉ giao hàng',
                    style: TextStyle(
                        color: AppColors.delivery,
                        fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.delivery),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openAddressPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.coffee),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(selected.recipientName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(selected.phone,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(selected.detailedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Text('Đổi',
                style: TextStyle(
                    color: AppColors.coffee, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _openAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final addresses = ref.watch(addressesProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Chọn địa chỉ giao hàng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 16),
                    addresses.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Lỗi: $e',
                          style: TextStyle(color: AppColors.textMuted)),
                      data: (list) {
                        if (list.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Chưa có địa chỉ nào',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted)),
                          );
                        }
                        return Column(
                          children: list.map((a) {
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined,
                                  color: AppColors.coffee),
                              title: Text(
                                  '${a.recipientName} • ${a.phone}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(a.detailedAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              onTap: () {
                                ref
                                    .read(checkoutProvider.notifier)
                                    .setDeliveryAddress(a);
                                Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const AddressFormScreen()));
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm địa chỉ mới'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Phương thức thanh toán ──────────────────────────────────────────
  Widget _paymentOption({
    required PaymentMethodType method,
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () =>
          ref.read(checkoutProvider.notifier).setPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.coffee : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.coffee : AppColors.textMuted,
                size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.coffee : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dùng điểm ───────────────────────────────────────────────────────
  // ─── Mã giảm giá ─────────────────────────────────────────────────────
  Widget _voucherChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: onRemove, child: const Text('Bỏ')),
        ],
      ),
    );
  }

  Widget _voucherSection(CheckoutState checkout) {
    final bothApplied = checkout.hasVoucher && checkout.hasShippingVoucher;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (checkout.hasVoucher)
          _voucherChip(
            'Đã áp dụng ${checkout.appliedCode}'
            ' (−${Formatters.money(checkout.voucher!.discount)})',
            () {
              _voucherController.clear();
              ref.read(checkoutProvider.notifier).removeVoucher();
            },
          ),
        if (checkout.hasShippingVoucher)
          _voucherChip(
            'Freeship ${checkout.shippingCode}'
            ' (−${Formatters.money(checkout.shippingVoucher!.discount)} phí ship)',
            () {
              _voucherController.clear();
              ref.read(checkoutProvider.notifier).removeShippingVoucher();
            },
          ),
        if (!bothApplied)
          Row(
            children: [
        Expanded(
          child: TextField(
            controller: _voucherController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Nhập mã giảm giá / freeship',
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 104,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(104, 54),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            onPressed: checkout.validatingVoucher
                ? null
                : () => ref
                    .read(checkoutProvider.notifier)
                    .applyVoucher(_voucherController.text),
            child: checkout.validatingVoucher
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Áp dụng'),
          ),
        ),
      ],
          ),
        _walletPicker(checkout),
      ],
    );
  }

  // Gợi ý voucher trong ví — bấm 1 chạm để áp.
  Widget _walletPicker(CheckoutState checkout) {
    final async = ref.watch(availableVouchersProvider);
    return async.maybeWhen(
      data: (list) {
        final usable = list
            .where((v) =>
                v.remainingForMe > 0 &&
                v.code != checkout.appliedCode &&
                v.code != checkout.shippingCode)
            .toList();
        if (usable.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text('Voucher của bạn',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            ...usable.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: checkout.validatingVoucher
                        ? null
                        : () => ref
                            .read(checkoutProvider.notifier)
                            .applyVoucher(v.code),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.coffee.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              v.type == 'SHIPPING'
                                  ? Icons.local_shipping_rounded
                                  : Icons.confirmation_number_rounded,
                              color: AppColors.coffee,
                              size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(_walletVoucherDesc(v),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('Dùng',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coffee)),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  String _walletVoucherDesc(VoucherWallet v) {
    final d = v.type == 'PERCENTAGE'
        ? 'Giảm ${v.discountValue}%'
        : v.type == 'SHIPPING'
            ? 'Giảm ship ${Formatters.money(v.discountValue)}'
            : 'Giảm ${Formatters.money(v.discountValue)}';
    if (v.minOrderValue > 0) {
      return '$d · Đơn từ ${Formatters.money(v.minOrderValue)}';
    }
    return d;
  }

  // ─── Dùng điểm ───────────────────────────────────────────────────────
  Widget _pointsSection(int subtotal) {
    final balanceAsync = ref.watch(loyaltyBalanceProvider);
    return balanceAsync.when(
      loading: () => _pointsCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
      error: (e, _) => _pointsCard(
        child: Text('Không tải được điểm thưởng',
            style: TextStyle(color: AppColors.textMuted)),
      ),
      data: (balance) {
        final maxPoints =
            LoyaltyConfig.maxRedeemablePoints(subtotal, balance.balance);

        // Chưa có điểm hoặc đơn quá nhỏ để dùng → hiện trạng thái thông báo.
        if (balance.balance <= 0 || maxPoints <= 0) {
          return _pointsCard(
            child: Row(
              children: [
                Icon(Icons.card_giftcard_outlined,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    balance.balance <= 0
                        ? 'Bạn có 0 điểm. Hoàn tất đơn để tích điểm và dùng giảm giá ở lần sau.'
                        : 'Đơn chưa đủ điều kiện dùng điểm.',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        final rawUsed = ref.watch(checkoutProvider).pointsToRedeem;
        // Kẹp lại để không vượt mức tối đa của đơn.
        final used = rawUsed > maxPoints ? maxPoints : (rawUsed < 0 ? 0 : rawUsed);
        if (used != rawUsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(checkoutProvider.notifier).setPointsToRedeem(used);
          });
        }
        final notifier = ref.read(checkoutProvider.notifier);
        return _pointsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: AppColors.coffee, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Dùng điểm (có ${balance.balance} điểm)',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  if (used > 0)
                    Text(
                        '−${Formatters.money(LoyaltyConfig.pointsToValue(used))}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stepBtn(Icons.remove_rounded,
                      used > 0 ? () => notifier.setPointsToRedeem(used - 1) : null),
                  Expanded(
                    child: Text('$used / $maxPoints điểm',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  _stepBtn(
                      Icons.add_rounded,
                      used < maxPoints
                          ? () => notifier.setPointsToRedeem(used + 1)
                          : null),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: used == maxPoints
                        ? () => notifier.setPointsToRedeem(0)
                        : () => notifier.setPointsToRedeem(maxPoints),
                    child: Text(used == maxPoints ? 'Bỏ' : 'Tối đa'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('1 điểm = ${Formatters.money(LoyaltyConfig.pointValue)}',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFE5DDD7)
              : AppColors.coffee.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 22,
            color: onTap == null ? AppColors.textMuted : AppColors.coffee),
      ),
    );
  }

  Widget _pointsCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  // ─── Tổng kết ────────────────────────────────────────────────────────
  Widget _summaryCard(
      int subtotal, int discount, int pointsDiscount, int total,
      int shipFee, dynamic ship, bool isDelivery, int shipDiscount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Tạm tính', subtotal),
          if (discount > 0) _row('Giảm voucher', -discount),
          if (pointsDiscount > 0) _row('Giảm bằng điểm', -pointsDiscount),
          if (isDelivery) _shipRow(shipFee, ship),
          if (shipDiscount > 0) _row('Giảm phí ship', -shipDiscount),
          const Divider(height: 18),
          _row('Tổng cộng', total, bold: true),
        ],
      ),
    );
  }

  /// Dòng phí giao hàng (kèm khoảng cách nếu có).
  Widget _shipRow(int shipFee, dynamic ship) {
    final km = ship?.distanceKm as double?;
    final label = km != null && km > 0
        ? 'Phí giao hàng (${km.toStringAsFixed(1)} km)'
        : 'Phí giao hàng';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted)),
          Text(
            shipFee == 0 ? 'Miễn phí' : Formatters.money(shipFee),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: shipFee == 0 ? Colors.green.shade700 : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Lưu ý khi chuyển khoản — kèm địa chỉ quán để khách đối chiếu.
  Widget _bankNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.coffee.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.coffee),
              SizedBox(width: 6),
              Text('Lưu ý khi chuyển khoản',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Chuyển đúng số tiền và giữ nguyên nội dung chuyển khoản để '
            'hệ thống tự xác nhận đơn.\n'
            '• Đơn được xử lý ngay sau khi nhận được tiền.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text('Địa chỉ quán',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Số 207, đường Thủy Nguyên, Ecopark, thị trấn Văn Giang, '
            'tỉnh Hưng Yên',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 6),
          Text('Hỗ trợ: 0338316893',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _row(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
      color: bold ? AppColors.coffee : AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${amount < 0 ? '−' : ''}${Formatters.money(amount.abs())}',
              style: style),
        ],
      ),
    );
  }
}
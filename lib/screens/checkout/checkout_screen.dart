// ============================================================
//  FLUTTER — lib/screens/checkout/checkout_screen.dart
//  >> GIAO DIỆN "SÂN KHẤU TỐI" (đồng bộ Trang chủ)
//  Đặt đơn: hình thức nhận hàng (Giao hàng/Tự lấy) + địa chỉ giao + giờ nhận +
//  phương thức thanh toán + voucher + dùng điểm → POST /orders.
//  BANK_QR → màn QR; COD → màn thành công. Logic GIỮ NGUYÊN.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/loyalty_config.dart';
import '../../core/config/store_info.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/address_model.dart';
import '../../models/order_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/shipping_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/stage.dart';
import '../address/address_form_screen.dart';
import 'order_success_screen.dart';
import 'qr_payment_screen.dart';
import 'voucher_select_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _addressInitialized = false;
  final _voucherController = TextEditingController();

  /// Màu nhấn của màn (theo món đầu tiên trong giỏ).
  Color _tint = DrinkTint.fallback;

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

    final cart = ref.watch(cartProvider);
    final tint =
        cart.isNotEmpty ? DrinkTint.of(cart.first.product) : DrinkTint.fallback;

    final canPlace = !placing &&
        isOpen &&
        !(checkout.isDelivery && checkout.deliveryAddress == null);

    _tint = tint;

    return StageScaffold(
      title: 'Thanh toán',
      subtitle: '${cart.fold<int>(0, (s, c) => s + c.quantity)} món · ${Formatters.money(subtotal)}',
      tint: tint,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (!isOpen) ...[
            _closedBanner(closedReason ?? 'Quán đang đóng cửa'),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Hình thức nhận hàng'),
          _fulfillmentToggle(checkout.fulfillment),
          if (checkout.isDelivery) ...[
            _sectionTitle('Địa chỉ giao hàng'),
            _addressSection(checkout.deliveryAddress),
          ],
          _sectionTitle('Giờ nhận'),
          _scheduleSection(checkout),
          _sectionTitle('Phương thức thanh toán'),
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
            subtitle: 'Quét VietQR · MoMo, ZaloPay, mọi ngân hàng',
          ),
          if (checkout.paymentMethod == PaymentMethodType.bankQr) ...[
            const SizedBox(height: 10),
            _bankNote(),
          ],
          _sectionTitle('Mã giảm giá'),
          _voucherSection(checkout),
          _sectionTitle('Dùng điểm thưởng'),
          _pointsSection(subtotal),
          _sectionTitle('Chi tiết thanh toán'),
          _summaryCard(subtotal, itemDiscount, pointsDiscount, grandTotal,
              shipFee, ship, checkout.isDelivery, shipDiscount),
        ],
      ),
      bottomBar: Container(
        decoration: BoxDecoration(
          color: St.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
              top: BorderSide(color: St.line(0.10))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng cộng',
                        style: TextStyle(
                            color: St.fg(0.6),
                            fontSize: 12.5)),
                    Text(Formatters.money(grandTotal),
                        style:  TextStyle(
                            color: St.fg(),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StageButton(
                    tint: tint,
                    loading: placing,
                    icon: isOpen ? Icons.check_rounded : Icons.storefront_rounded,
                    label: isOpen ? 'Đặt hàng' : 'Quán đang đóng cửa',
                    onTap: canPlace
                        ? () => ref
                            .read(placeOrderControllerProvider.notifier)
                            .placeOrder()
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _scheduleOption(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return StageGlass(
      onTap: onTap,
      highlight: selected ? _tint : null,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 18,
              color: St.fg(selected ? 1 : 0.65)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: St.fg(selected ? 1 : 0.75))),
        ],
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
              child: _scheduleOption(
                  Icons.bolt_rounded, 'Giao ngay', scheduled == null, () {
                ref.read(checkoutProvider.notifier).setScheduledFor(null);
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scheduleOption(Icons.schedule_rounded, 'Hẹn giờ',
                  scheduled != null, pick),
            ),
          ],
        ),
        if (scheduled != null) ...[
          const SizedBox(height: 10),
          StageGlass(
            onTap: pick,
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                 Icon(Icons.access_time_rounded,
                    color: St.fg(), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Nhận lúc ${_fmtSchedule(scheduled)}',
                      style:  TextStyle(
                          color: St.fg(), fontWeight: FontWeight.w700)),
                ),
                Text('Đổi',
                    style: TextStyle(
                        color: St.fg(0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10, left: 2),
        child: Text(text,
            style:  TextStyle(
                color: St.fg(),
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      );

  // ─── Băng "đóng cửa" ─────────────────────────────────────────────────
  Widget _closedBanner(String reason) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE23E57).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFFFF8A9B).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFFFFB3BE)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Quán đang đóng cửa',
                      style: TextStyle(
                          color: St.fg(), fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(reason,
                      style: TextStyle(
                          fontSize: 13,
                          color: St.fg(0.8))),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Hình thức nhận hàng ─────────────────────────────────────────────
  Widget _fulfillmentToggle(FulfillmentType current) {
    Widget opt(FulfillmentType type, IconData icon, String hint) {
      final selected = current == type;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: StageGlass(
            onTap: () =>
                ref.read(checkoutProvider.notifier).setFulfillment(type),
            highlight: selected ? _tint : null,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(icon,
                    color: St.fg(selected ? 1 : 0.6),
                    size: 28),
                const SizedBox(height: 6),
                Text(type.label,
                    style: TextStyle(
                        color:
                            St.fg(selected ? 1 : 0.8),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(hint,
                    style: TextStyle(
                        color: St.fg(0.55),
                        fontSize: 11.5)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opt(FulfillmentType.delivery, Icons.delivery_dining_rounded,
            'Ship tận nơi'),
        const SizedBox(width: 10),
        opt(FulfillmentType.pickup, Icons.storefront_rounded,
            'Không phí ship'),
      ],
    );
  }

  // ─── Địa chỉ giao hàng ───────────────────────────────────────────────
  Widget _addressSection(AddressModel? selected) {
    if (selected == null) {
      return StageGlass(
        onTap: _openAddressPicker,
        highlight: const Color(0xFFFF8A9B),
        radius: 18,
        child:  Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: St.fg()),
            SizedBox(width: 12),
            Expanded(
              child: Text('Chọn hoặc thêm địa chỉ giao hàng',
                  style: TextStyle(
                      color: St.fg(), fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded, color: St.fg()),
          ],
        ),
      );
    }

    return StageGlass(
      onTap: _openAddressPicker,
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: St.fill(0.12),
            ),
            child:  Icon(Icons.location_on_rounded,
                color: St.fg(), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${selected.recipientName} · ${selected.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                        color: St.fg(), fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(selected.detailedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: St.fg(0.65),
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('Đổi',
              style: TextStyle(
                  color: St.fg(0.85),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _openAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: St.sheet,
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
                     Text('Chọn địa chỉ giao hàng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: St.fg(),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
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
                              leading: Icon(Icons.location_on_outlined,
                                  color: St.fg(0.8)),
                              title: Text(
                                  '${a.recipientName} • ${a.phone}',
                                  style:  TextStyle(
                                      color: St.fg(),
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(a.detailedAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: St.fg()
                                          .withValues(alpha: 0.6))),
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
                    StageButton(
                      label: 'Thêm địa chỉ mới',
                      icon: Icons.add_rounded,
                      white: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const AddressFormScreen()));
                      },
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
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: StageGlass(
        onTap: () =>
            ref.read(checkoutProvider.notifier).setPaymentMethod(method),
        highlight: selected ? _tint : null,
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: St.fill(0.12),
              ),
              child: Icon(icon, color: St.fg(), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:  TextStyle(
                          color: St.fg(), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: St.fg(0.6),
                          fontSize: 12)),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: on ? St.line(1) : St.line(0.4),
              width: 2),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? 10 : 0,
            height: on ? 10 : 0,
            decoration:  BoxDecoration(
                shape: BoxShape.circle, color: St.solid),
          ),
        ),
      );

  // ─── Mã giảm giá ─────────────────────────────────────────────────────
  Widget _voucherChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StageGlass(
        highlight: const Color(0xFF4ADE80),
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
             Icon(Icons.local_offer_rounded,
                color: St.fg(), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style:  TextStyle(
                      color: St.fg(), fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: onRemove,
              child: Text('Bỏ',
                  style: TextStyle(
                      color: St.fg(0.85),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voucherSection(CheckoutState checkout) {
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
        // Nút "Thêm voucher" -> mở danh sách voucher trong ví.
        StageGlass(
          onTap: _showVoucherSheet,
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
               Icon(Icons.confirmation_number_rounded,
                  color: St.fg(), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    checkout.hasVoucher || checkout.hasShippingVoucher
                        ? 'Đổi / thêm voucher'
                        : 'Chọn voucher hoặc nhập mã',
                    style:  TextStyle(
                        fontWeight: FontWeight.w700,
                        color: St.fg(),
                        fontSize: 14.5)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: St.fg(0.7)),
            ],
          ),
        ),
      ],
    );
  }

  // Bảng chọn voucher: hiện TẤT CẢ voucher trong ví. Đủ điều kiện -> sáng +
  // tích được; không đủ -> tối + khoá. Vẫn có ô nhập mã thủ công.
  void _showVoucherSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VoucherSelectScreen()),
    );
  }

  // ─── Dùng điểm ───────────────────────────────────────────────────────
  Widget _pointsSection(int subtotal) {
    final balanceAsync = ref.watch(loyaltyBalanceProvider);
    return balanceAsync.when(
      loading: () => _pointsCard(
        child:  Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: St.fg(0.7))),
          ),
        ),
      ),
      error: (e, _) => _pointsCard(
        child: Text('Không tải được điểm thưởng',
            style: TextStyle(color: St.fg(0.6))),
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
                    color: St.fg(0.6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    balance.balance <= 0
                        ? 'Bạn có 0 điểm. Hoàn tất đơn để tích điểm và dùng giảm giá ở lần sau.'
                        : 'Đơn chưa đủ điều kiện dùng điểm.',
                    style: TextStyle(
                        color: St.fg(0.65),
                        fontSize: 13),
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
                   Icon(Icons.card_giftcard_rounded,
                      color: St.fg(), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Dùng điểm (có ${balance.balance} điểm)',
                        style:  TextStyle(
                            color: St.fg(), fontWeight: FontWeight.w700)),
                  ),
                  if (used > 0)
                    Text(
                        '−${Formatters.money(LoyaltyConfig.pointsToValue(used))}',
                        style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w800)),
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
                        style:  TextStyle(
                            color: St.fg(),
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
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
                    child: Text(used == maxPoints ? 'Bỏ' : 'Tối đa',
                        style:  TextStyle(
                            color: St.fg(), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('1 điểm = ${Formatters.money(LoyaltyConfig.pointValue)}',
                  style: TextStyle(
                      color: St.fg(0.5),
                      fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: St.fill(enabled ? 0.14 : 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon,
              size: 20,
              color: St.fg(enabled ? 1 : 0.35)),
        ),
      ),
    );
  }

  Widget _pointsCard({required Widget child}) =>
      StageGlass(radius: 18, child: child);

  // ─── Tổng kết ────────────────────────────────────────────────────────
  Widget _summaryCard(
      int subtotal, int discount, int pointsDiscount, int total,
      int shipFee, dynamic ship, bool isDelivery, int shipDiscount) {
    return StageGlass(
      radius: 18,
      child: Column(
        children: [
          _row('Tạm tính', subtotal),
          if (discount > 0) _row('Giảm voucher', -discount),
          if (pointsDiscount > 0) _row('Giảm bằng điểm', -pointsDiscount),
          if (isDelivery) _shipRow(shipFee, ship),
          if (shipDiscount > 0) _row('Giảm phí ship', -shipDiscount),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Divider(height: 1, color: St.line(0.1)),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: St.fg(0.7))),
          Text(
            shipFee == 0 ? 'Miễn phí' : Formatters.money(shipFee),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: shipFee == 0
                  ? const Color(0xFF4ADE80)
                  : St.fg(0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Lưu ý khi chuyển khoản — kèm địa chỉ quán để khách đối chiếu.
  Widget _bankNote() {
    final muted = St.fg(0.7);
    return StageGlass(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: St.fg()),
              SizedBox(width: 6),
              Text('Lưu ý khi chuyển khoản',
                  style: TextStyle(
                      color: St.fg(), fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Chuyển đúng số tiền và giữ nguyên nội dung chuyển khoản để '
            'hệ thống tự xác nhận đơn.\n'
            '• Đơn được xử lý ngay sau khi nhận được tiền.',
            style: TextStyle(fontSize: 13, height: 1.5, color: muted),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: St.line(0.1)),
          const SizedBox(height: 10),
           Text('Địa chỉ quán',
              style: TextStyle(
                  color: St.fg(),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 4),
          Text(StoreInfo.address,
              style: TextStyle(fontSize: 13, height: 1.45, color: muted)),
          if (StoreInfo.hotline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Hỗ trợ: ${StoreInfo.hotline}',
                style: TextStyle(fontSize: 13, color: muted)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
      color: bold
          ? St.fg()
          : (amount < 0
              ? const Color(0xFF4ADE80)
              : St.fg(0.75)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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

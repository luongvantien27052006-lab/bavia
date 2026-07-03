// lib/providers/checkout_provider.dart
//
// Trạng thái thanh toán: mã voucher đã áp, phương thức thanh toán, và các
// con số tạm tính/giảm/tổng. Voucher tự huỷ khi giỏ thay đổi (vì
// validationToken được ký theo đúng giỏ tại thời điểm validate).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/loyalty_config.dart';
import '../core/network/api_exception.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';
import '../models/voucher_model.dart';
import 'cart_provider.dart';
import 'repository_providers.dart';

/// Hình thức nhận hàng.
enum FulfillmentType {
  delivery('Giao hàng'),
  pickup('Tự lấy');

  final String label;
  const FulfillmentType(this.label);
}

class CheckoutState {
  final PaymentMethodType paymentMethod;
  final FulfillmentType fulfillment;
  final AddressModel? deliveryAddress; // chỉ dùng khi fulfillment = delivery
  final int pointsToRedeem; // 0 = không dùng điểm
  final VoucherValidation? voucher; // null = chưa áp mã
  final String? appliedCode; // mã người dùng đã nhập (vd WELCOME10)
  final bool validatingVoucher;
  final String? voucherError;

  const CheckoutState({
    this.paymentMethod = PaymentMethodType.cod,
    this.fulfillment = FulfillmentType.delivery,
    this.deliveryAddress,
    this.pointsToRedeem = 0,
    this.voucher,
    this.appliedCode,
    this.validatingVoucher = false,
    this.voucherError,
  });

  bool get hasVoucher => voucher != null && voucher!.valid;
  bool get isDelivery => fulfillment == FulfillmentType.delivery;

  CheckoutState copyWith({
    PaymentMethodType? paymentMethod,
    FulfillmentType? fulfillment,
    Object? deliveryAddress = _sentinel,
    int? pointsToRedeem,
    Object? voucher = _sentinel,
    Object? appliedCode = _sentinel,
    bool? validatingVoucher,
    Object? voucherError = _sentinel,
  }) {
    return CheckoutState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fulfillment: fulfillment ?? this.fulfillment,
      deliveryAddress: identical(deliveryAddress, _sentinel)
          ? this.deliveryAddress
          : deliveryAddress as AddressModel?,
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      voucher: identical(voucher, _sentinel)
          ? this.voucher
          : voucher as VoucherValidation?,
      appliedCode: identical(appliedCode, _sentinel)
          ? this.appliedCode
          : appliedCode as String?,
      validatingVoucher: validatingVoucher ?? this.validatingVoucher,
      voucherError: identical(voucherError, _sentinel)
          ? this.voucherError
          : voucherError as String?,
    );
  }

  static const _sentinel = Object();
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    // Khi giỏ thay đổi → huỷ voucher đã áp + reset điểm dùng (token & mức điểm
    // cũ không còn hợp lệ với giỏ mới).
    ref.listen(cartProvider, (prev, next) {
      if (prev == null) return;
      if (state.hasVoucher || state.pointsToRedeem > 0) {
        state = state.copyWith(
            voucher: null,
            appliedCode: null,
            voucherError: null,
            pointsToRedeem: 0);
      }
    });
    return const CheckoutState();
  }

  void setPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setFulfillment(FulfillmentType type) {
    // Chuyển sang Tự lấy thì bỏ địa chỉ giao.
    if (type == FulfillmentType.pickup) {
      state = state.copyWith(fulfillment: type, deliveryAddress: null);
    } else {
      state = state.copyWith(fulfillment: type);
    }
  }

  void setDeliveryAddress(AddressModel? address) {
    state = state.copyWith(deliveryAddress: address);
  }

  void setPointsToRedeem(int points) {
    state = state.copyWith(pointsToRedeem: points < 0 ? 0 : points);
  }

  Future<void> applyVoucher(String code) async {
    if (code.trim().isEmpty) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = state.copyWith(voucherError: 'Giỏ hàng đang trống');
      return;
    }

    state = state.copyWith(validatingVoucher: true, voucherError: null);
    try {
      final result = await ref.read(voucherRepositoryProvider).validate(
            voucherCode: code,
            cartItems: cart
                .map((i) => (productId: i.product.id, quantity: i.quantity))
                .toList(),
          );
      if (result.valid) {
        state = state.copyWith(
            voucher: result,
            appliedCode: code.trim().toUpperCase(),
            validatingVoucher: false,
            voucherError: null);
      } else {
        state = state.copyWith(
          voucher: null,
          appliedCode: null,
          validatingVoucher: false,
          voucherError: result.message ?? 'Mã không hợp lệ',
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(
          voucher: null,
          appliedCode: null,
          validatingVoucher: false,
          voucherError: e.message);
    }
  }

  void removeVoucher() {
    state = state.copyWith(voucher: null, appliedCode: null, voucherError: null);
  }

  void reset() => state = const CheckoutState();
}

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

/// Số tiền giảm từ voucher (0 nếu không có voucher).
final checkoutDiscountProvider = Provider<int>((ref) {
  final co = ref.watch(checkoutProvider);
  return co.hasVoucher ? co.voucher!.discount : 0;
});

/// Số tiền giảm từ điểm thưởng (ước tính phía client).
final checkoutPointsDiscountProvider = Provider<int>((ref) {
  final pts = ref.watch(checkoutProvider).pointsToRedeem;
  return LoyaltyConfig.pointsToValue(pts);
});

/// Tổng phải trả = (tạm tính - giảm voucher) - giảm điểm. Không âm.
final checkoutTotalProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final co = ref.watch(checkoutProvider);
  final base = co.hasVoucher ? co.voucher!.finalAmount : subtotal;
  final pointsValue =
      LoyaltyConfig.pointsToValue(co.pointsToRedeem);
  final total = base - pointsValue;
  return total < 0 ? 0 : total;
});

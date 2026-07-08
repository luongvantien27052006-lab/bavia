// ============================================================
//  FLUTTER
//  lib/repositories/voucher_repository.dart
//  >> CHEP DE (them fetchAvailable)
// ============================================================

// lib/repositories/voucher_repository.dart
//
// POST /api/vouchers/validate — kiểm tra mã giảm giá trước khi đặt đơn.
// Body: { voucherCode, cartItems: [{ product_id, quantity }] }.
// Trả về discount + validationToken (HMAC) — phải gửi token này lại khi
// đặt đơn để backend xác thực mức giảm.

import '../core/network/api_client.dart';
import '../models/voucher_model.dart';
import '../models/voucher_wallet.dart';

class VoucherRepository {
  final ApiClient _api = ApiClient.I;

  /// Ví voucher của khách: GET /vouchers/available.
  Future<List<VoucherWallet>> fetchAvailable() async {
    final data = await _api.get('/vouchers/available');
    final map = Map<String, dynamic>.from(data as Map);
    final items = (map['items'] as List?) ?? const [];
    return items
        .map((e) => VoucherWallet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<VoucherValidation> validate({
    required String voucherCode,
    required List<({String productId, int quantity})> cartItems,
  }) async {
    final data = await _api.post(
      '/vouchers/validate',
      data: {
        'voucherCode': voucherCode.trim().toUpperCase(),
        'cartItems': cartItems
            .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
            .toList(),
      },
    );
    return VoucherValidation.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
// lib/models/voucher_model.dart
//
// Kết quả POST /api/vouchers/validate:
//   { valid, voucherId, voucherName, discount, finalAmount, validationToken }
//
// validationToken là HMAC do backend ký — client PHẢI gửi lại nguyên vẹn
// khi đặt đơn (POST /orders) để backend xác thực mức giảm không bị sửa.

import 'json_x.dart';

class VoucherValidation {
  final bool valid;
  final String? voucherId;
  final String? voucherName;
  final int discount; // số tiền giảm (VND)
  final int finalAmount; // tổng sau giảm (VND)
  final String? validationToken;
  final String? message; // lý do nếu không hợp lệ

  const VoucherValidation({
    required this.valid,
    required this.discount,
    required this.finalAmount,
    this.voucherId,
    this.voucherName,
    this.validationToken,
    this.message,
  });

  factory VoucherValidation.fromJson(Map<String, dynamic> json) {
    return VoucherValidation(
      valid: JsonX.boolVal(json, ['valid', 'isValid']),
      voucherId: JsonX.strOrNull(json, ['voucherId', 'voucher_id']),
      voucherName: JsonX.strOrNull(json, ['voucherName', 'voucher_name']),
      discount: JsonX.intVal(json, ['discount', 'discountAmount']),
      finalAmount: JsonX.intVal(json, ['finalAmount', 'final_amount']),
      validationToken:
          JsonX.strOrNull(json, ['validationToken', 'validation_token']),
      message: JsonX.strOrNull(json, ['message']),
    );
  }
}

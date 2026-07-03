// lib/models/order_model.dart
//
// Đơn hàng + item + thông tin thanh toán QR.
// Map theo các cột orders/order_items trong backend (snake_case) + response
// { order, payment } khi đặt đơn BANK_QR.

import 'json_x.dart';

// ─── Enums ─────────────────────────────────────────────────────────────

enum PaymentMethodType {
  cod('COD', 'Tiền mặt khi nhận hàng'),
  bankQr('BANK_QR', 'Chuyển khoản QR');

  final String apiValue;
  final String label;
  const PaymentMethodType(this.apiValue, this.label);
}

enum OrderStatus {
  pending('PENDING', 'Chờ xác nhận'),
  confirmed('CONFIRMED', 'Đã xác nhận'),
  inProgress('IN_PROGRESS', 'Đang pha chế'),
  ready('READY', 'Sẵn sàng'),
  delivered('DELIVERED', 'Đã giao'),
  cancelled('CANCELLED', 'Đã huỷ'),
  refunded('REFUNDED', 'Đã hoàn tiền'),
  unknown('UNKNOWN', 'Không rõ');

  final String apiValue;
  final String label;
  const OrderStatus(this.apiValue, this.label);

  static OrderStatus fromApi(String? v) => OrderStatus.values.firstWhere(
        (s) => s.apiValue == v,
        orElse: () => OrderStatus.unknown,
      );

  bool get isCancellable =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.inProgress;
  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;
}

enum PaymentStatus {
  awaitingPayment('AWAITING_PAYMENT', 'Chờ thanh toán'),
  confirmed('CONFIRMED', 'Đã thanh toán'),
  paymentError('PAYMENT_ERROR', 'Lỗi thanh toán'),
  expired('EXPIRED', 'Hết hạn'),
  unknown('UNKNOWN', 'Không rõ');

  final String apiValue;
  final String label;
  const PaymentStatus(this.apiValue, this.label);

  static PaymentStatus fromApi(String? v) => PaymentStatus.values.firstWhere(
        (s) => s.apiValue == v,
        orElse: () => PaymentStatus.unknown,
      );
}

// ─── Order item ─────────────────────────────────────────────────────────

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice; // giá tại thời điểm đặt
  final int lineTotal; // = unitPrice * quantity (nếu backend trả)

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = JsonX.intVal(json, ['quantity', 'qty'], fallback: 1);
    final unit = JsonX.intVal(json, ['unit_price', 'unitPrice', 'price']);
    return OrderItem(
      productId: JsonX.str(json, ['product_id', 'productId']),
      productName: JsonX.str(json, ['product_name', 'productName', 'name']),
      quantity: qty,
      unitPrice: unit,
      lineTotal:
          JsonX.intVal(json, ['line_total', 'lineTotal', 'total'], fallback: unit * qty),
    );
  }
}

// ─── Payment info (BANK_QR) ───────────────────────────────────────────────

class PaymentInfo {
  final String qrImageUrl;
  final String transferContent;
  final int amount;
  final DateTime? expiresAt;
  final String? bankAccountNo;
  final String? bankAccountName;

  const PaymentInfo({
    required this.qrImageUrl,
    required this.transferContent,
    required this.amount,
    this.expiresAt,
    this.bankAccountNo,
    this.bankAccountName,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final bank = JsonX.map(json, ['bankInfo', 'bank_info']) ?? const {};
    return PaymentInfo(
      qrImageUrl: JsonX.str(json, ['qrImageUrl', 'qr_image_url', 'qrUrl']),
      transferContent:
          JsonX.str(json, ['transferContent', 'transfer_content', 'content']),
      amount: JsonX.intVal(json, ['amount', 'finalAmount', 'final_amount']),
      expiresAt: JsonX.dateTime(json, ['expiresAt', 'expires_at']),
      bankAccountNo: JsonX.strOrNull(bank, ['accountNo', 'account_no']) ??
          JsonX.strOrNull(json, ['accountNo', 'account_no']),
      bankAccountName: JsonX.strOrNull(bank, ['accountName', 'account_name']) ??
          JsonX.strOrNull(json, ['accountName', 'account_name']),
    );
  }
}

// ─── Order ─────────────────────────────────────────────────────────────

class OrderModel {
  final String id;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethodType? paymentMethod;
  final int finalAmount;
  final int discountAmount;
  final int pointsEarned;
  final String? voucherId;
  final List<OrderItem> items;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.finalAmount,
    this.paymentMethod,
    this.discountAmount = 0,
    this.pointsEarned = 0,
    this.voucherId,
    this.items = const [],
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final pm = JsonX.strOrNull(json, ['payment_method', 'paymentMethod']);
    return OrderModel(
      id: JsonX.str(json, ['id']),
      status: OrderStatus.fromApi(JsonX.strOrNull(json, ['status'])),
      paymentStatus: PaymentStatus.fromApi(
          JsonX.strOrNull(json, ['payment_status', 'paymentStatus'])),
      paymentMethod: pm == null
          ? null
          : PaymentMethodType.values.firstWhere(
              (m) => m.apiValue == pm,
              orElse: () => PaymentMethodType.cod,
            ),
      finalAmount: JsonX.intVal(json, ['final_amount', 'finalAmount']),
      discountAmount:
          JsonX.intVal(json, ['discount_amount', 'discountAmount']),
      pointsEarned: JsonX.intVal(json, ['points_earned', 'pointsEarned']),
      voucherId: JsonX.strOrNull(json, ['voucher_id', 'voucherId']),
      items: JsonX
          .list(json, ['items', 'order_items', 'orderItems'])
          .whereType<Map>()
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: JsonX.dateTime(json, ['created_at', 'createdAt']),
    );
  }
}

/// Kết quả đặt đơn: order + (tuỳ chọn) payment khi chọn BANK_QR.
class PlaceOrderResult {
  final OrderModel order;
  final PaymentInfo? payment;

  const PlaceOrderResult({required this.order, this.payment});

  factory PlaceOrderResult.fromJson(Map<String, dynamic> json) {
    // Backend trả { order, payment } cho BANK_QR; còn COD có thể trả thẳng order.
    final orderJson = JsonX.map(json, ['order']) ?? json;
    final paymentJson = JsonX.map(json, ['payment']);
    return PlaceOrderResult(
      order: OrderModel.fromJson(orderJson),
      payment: paymentJson == null ? null : PaymentInfo.fromJson(paymentJson),
    );
  }
}
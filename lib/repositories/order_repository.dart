// ==================================================================
//  FLUTTER APP  (package bavia)
//  Dat tai:  lib/repositories/order_repository.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/repositories/order_repository.dart
//
// Đặt đơn + xem lịch sử + huỷ đơn.
// Routes:
//   POST   /api/orders               → đặt đơn (COD trả order; BANK_QR trả order+payment)
//   GET    /api/orders?limit=&offset= → lịch sử đơn của khách
//   GET    /api/orders/:id           → chi tiết đơn kèm items
//   POST   /api/orders/:id/cancel    → khách tự huỷ (chỉ khi PENDING)

import '../core/network/api_client.dart';
import '../models/order_model.dart';
import '../models/paginated.dart';
import '../models/product.dart';

class OrderRepository {
  final ApiClient _api = ApiClient.I;

  /// Đặt đơn. [validationToken] lấy từ kết quả validate voucher (nếu có mã).
  /// [deliveryAddress] là object tự do (backend lưu JSONB) — KHÔNG phải address_id.
  Future<PlaceOrderResult> placeOrder({
    required List<({String productId, int quantity, List<ProductOption> options})>
        items,
    required PaymentMethodType paymentMethod,
    String? voucherCode,
    String? validationToken,
    int? pointsToRedeem,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    final data = await _api.post(
      '/orders',
      data: {
        'items': items
            .map((i) => {
                  'product_id': i.productId,
                  'quantity': i.quantity,
                  if (i.options.isNotEmpty)
                    'options': i.options.map((o) => o.toJson()).toList(),
                })
            .toList(),
        'paymentMethod': paymentMethod.apiValue,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucherCode': voucherCode.trim().toUpperCase(),
        if (validationToken != null) 'validationToken': validationToken,
        if (pointsToRedeem != null && pointsToRedeem > 0)
          'pointsToRedeem': pointsToRedeem,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      },
    );
    return PlaceOrderResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Paginated<OrderModel>> fetchOrders({
    int limit = 50,
    int offset = 0,
  }) async {
    final data =
        await _api.get('/orders', query: {'limit': limit, 'offset': offset});
    // Backend có thể trả { items, pagination } hoặc thẳng list.
    if (data is List) {
      return Paginated<OrderModel>(
        items: data
            .whereType<Map>()
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        limit: limit,
        offset: offset,
        count: data.length,
      );
    }
    return Paginated<OrderModel>.fromJson(
      Map<String, dynamic>.from(data as Map),
      OrderModel.fromJson,
    );
  }

  Future<OrderModel> fetchOrderById(String id) async {
    final data = await _api.get('/orders/$id');
    final map = Map<String, dynamic>.from(data as Map);
    final inner = map['order'] is Map
        ? Map<String, dynamic>.from(map['order'] as Map)
        : map;
    return OrderModel.fromJson(inner);
  }

  /// Huỷ đơn. Trả về { id, status, refunded }.
  Future<({String id, OrderStatus status, bool refunded})> cancelOrder(
      String id) async {
    final data = await _api.post('/orders/$id/cancel');
    final map = Map<String, dynamic>.from(data as Map);
    return (
      id: map['id']?.toString() ?? id,
      status: OrderStatus.fromApi(map['status']?.toString()),
      refunded: map['refunded'] == true,
    );
  }
}
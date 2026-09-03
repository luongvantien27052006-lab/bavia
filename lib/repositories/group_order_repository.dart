// lib/repositories/group_order_repository.dart

import '../core/network/api_client.dart';
import '../models/group_order.dart';
import '../models/product.dart';
import '../models/order_model.dart';

class GroupOrderRepository {
  final ApiClient _api = ApiClient.I;

  GroupOrder _parse(dynamic data) =>
      GroupOrder.fromJson(Map<String, dynamic>.from(data as Map));

  Future<GroupOrder> createRoom({
    required String fulfillment,
    Map<String, dynamic>? deliveryAddress,
    int? spendingLimit,
    String? paymentMode,
    String? splitMethod,
  }) async {
    final data = await _api.post('/group-orders', data: {
      'fulfillment': fulfillment,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (spendingLimit != null) 'spendingLimit': spendingLimit,
      if (paymentMode != null) 'paymentMode': paymentMode,
      if (splitMethod != null) 'splitMethod': splitMethod,
    });
    return _parse(data);
  }

  Future<GroupOrder> updateSettings(
    String id, {
    int? spendingLimit,
    String? paymentMode,
    String? splitMethod,
  }) async {
    final data = await _api.patch('/group-orders/$id/settings', data: {
      if (spendingLimit != null) 'spendingLimit': spendingLimit,
      if (paymentMode != null) 'paymentMode': paymentMode,
      if (splitMethod != null) 'splitMethod': splitMethod,
    });
    return _parse(data);
  }

  Future<GroupBill> getBill(String id) async {
    final data = await _api.get('/group-orders/$id/bill');
    return GroupBill.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<GroupOrder> join(String code) async {
    final data = await _api
        .post('/group-orders/join', data: {'code': code.trim().toUpperCase()});
    return _parse(data);
  }

  Future<GroupOrder> get(String id) async {
    final data = await _api.get('/group-orders/$id');
    return _parse(data);
  }

  Future<GroupOrder> addItem(
    String id, {
    required String productId,
    required int quantity,
    required List<ProductOption> options,
    required int unitPrice,
    required String productName,
    String? note,
  }) async {
    final data = await _api.post('/group-orders/$id/items', data: {
      'items': [
        {
          'product_id': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'productName': productName,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (options.isNotEmpty)
            'options': options.map((o) => o.toJson()).toList(),
        }
      ],
    });
    return _parse(data);
  }

  Future<GroupOrder> removeItem(String id, String itemId) async {
    final data = await _api.delete('/group-orders/$id/items/$itemId');
    return _parse(data);
  }

  Future<GroupOrder> setLocked(String id, bool locked) async {
    final data =
        await _api.post('/group-orders/$id/${locked ? 'lock' : 'unlock'}');
    return _parse(data);
  }

  Future<void> cancel(String id) async {
    await _api.post('/group-orders/$id/cancel');
  }

  Future<GroupOrder> startCollection(
    String id, {
    Map<String, dynamic>? deliveryAddress,
    String? voucherCode,
  }) async {
    final data = await _api.post('/group-orders/$id/collect', data: {
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucherCode': voucherCode,
    });
    return _parse(data);
  }

  Future<GroupOrder> submitPayment(String id) async {
    final data = await _api.post('/group-orders/$id/pay-submit');
    return _parse(data);
  }

  Future<GroupOrder> finalizeCollection(String id) async {
    final data = await _api.post('/group-orders/$id/finalize');
    return _parse(data);
  }

  Future<GroupOrder> cancelCollection(String id) async {
    final data = await _api.post('/group-orders/$id/cancel-collection');
    return _parse(data);
  }

  Future<PlaceOrderResult> checkout(
    String id, {
    required PaymentMethodType paymentMethod,
    Map<String, dynamic>? deliveryAddress,
    String? voucherCode,
    String? validationToken,
    String? shippingVoucherCode,
    String? shippingValidationToken,
  }) async {
    final data = await _api.post('/group-orders/$id/checkout', data: {
      'paymentMethod': paymentMethod.apiValue,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucherCode': voucherCode,
      if (validationToken != null) 'validationToken': validationToken,
      if (shippingVoucherCode != null && shippingVoucherCode.isNotEmpty)
        'shippingVoucherCode': shippingVoucherCode,
      if (shippingValidationToken != null)
        'shippingValidationToken': shippingValidationToken,
    });
    return PlaceOrderResult.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
// lib/repositories/address_repository.dart
//
// CRUD địa chỉ giao hàng. Route: GET/POST/PATCH/DELETE /api/addresses[/:id].
// Đặt mặc định = PATCH /addresses/:id với { is_default: true } (backend
// không có endpoint set-default riêng).

import '../core/network/api_client.dart';
import '../models/address_model.dart';

class AddressRepository {
  final ApiClient _api = ApiClient.I;

  Future<List<AddressModel>> fetchAddresses() async {
    final data = await _api.get('/addresses');
    // Có thể trả thẳng list, hoặc { items: [...] }.
    final List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['items'] is List) {
      rawList = data['items'] as List;
    } else {
      rawList = const [];
    }
    return rawList
        .whereType<Map>()
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    final data = await _api.post('/addresses', data: address.toCreateJson());
    return AddressModel.fromJson(_extract(data));
  }

  Future<AddressModel> updateAddress(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final data = await _api.patch('/addresses/$id', data: changes);
    return AddressModel.fromJson(_extract(data));
  }

  /// Đặt 1 địa chỉ làm mặc định.
  Future<AddressModel> setDefault(String id) =>
      updateAddress(id, {'isDefault': true});

  Future<void> deleteAddress(String id) => _api.delete('/addresses/$id');

  Map<String, dynamic> _extract(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return map['address'] is Map
        ? Map<String, dynamic>.from(map['address'] as Map)
        : map;
  }
}

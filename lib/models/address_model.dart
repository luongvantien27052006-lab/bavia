// lib/models/address_model.dart
//
// Địa chỉ giao hàng — map cho GET/POST/PATCH/DELETE /api/addresses.
//
// ⚠️ Khớp ĐÚNG backend (đã xác nhận từ schema + DTO):
//   - Cột DB: receiver_name, receiver_phone, detailed_address, is_default
//   - DTO nhận camelCase: receiverName, receiverPhone, detailedAddress, isDefault
//   - KHÔNG có cột "note" trong bảng addresses.
// Backend bật forbidNonWhitelisted nên gửi field lạ (recipient_name, note...) → 400.

import 'json_x.dart';

class AddressModel {
  final String id;
  final String recipientName; // hiển thị; map ↔ receiver_name / receiverName
  final String phone; // map ↔ receiver_phone / receiverPhone
  final String detailedAddress; // địa chỉ đầy đủ 1 chuỗi
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.detailedAddress,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: JsonX.str(json, ['id']),
      recipientName: JsonX.str(
          json, ['receiver_name', 'receiverName', 'recipient_name', 'name']),
      phone: JsonX.str(
          json, ['receiver_phone', 'receiverPhone', 'phone', 'phone_number']),
      detailedAddress: JsonX.str(
          json, ['detailed_address', 'detailedAddress', 'address']),
      isDefault: JsonX.boolVal(json, ['is_default', 'isDefault']),
    );
  }

  /// Body tạo địa chỉ — camelCase đúng DTO backend.
  Map<String, dynamic> toCreateJson() => {
        'receiverName': recipientName,
        'receiverPhone': phone,
        'detailedAddress': detailedAddress,
        'isDefault': isDefault,
      };

  /// Object đính kèm khi đặt đơn giao hàng (deliveryAddress — JSONB tự do).
  Map<String, dynamic> toDeliveryJson() => {
        'receiverName': recipientName,
        'receiverPhone': phone,
        'detailedAddress': detailedAddress,
      };

  AddressModel copyWith({
    String? recipientName,
    String? phone,
    String? detailedAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

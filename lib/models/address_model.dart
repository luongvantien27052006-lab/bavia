// ============================================================
//  FLUTTER
//  lib/models/address_model.dart
//  >> CHEP DE (them latitude/longitude)
// ============================================================

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
  /// Toạ độ — dùng để tính phí giao hàng theo khoảng cách.
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.detailedAddress,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  bool get hasCoords => latitude != null && longitude != null;

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
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
    );
  }

  /// Body tạo địa chỉ — camelCase đúng DTO backend.
  Map<String, dynamic> toCreateJson() => {
        'receiverName': recipientName,
        'receiverPhone': phone,
        'detailedAddress': detailedAddress,
        'isDefault': isDefault,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  /// Object đính kèm khi đặt đơn giao hàng (deliveryAddress — JSONB tự do).
  Map<String, dynamic> toDeliveryJson() => {
        'receiverName': recipientName,
        'receiverPhone': phone,
        'detailedAddress': detailedAddress,
        // Backend dùng 2 trường này để tính phí ship theo khoảng cách.
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  AddressModel copyWith({
    String? recipientName,
    String? phone,
    String? detailedAddress,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
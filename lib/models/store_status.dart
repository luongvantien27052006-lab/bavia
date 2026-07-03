// ==================================================================
//  FLUTTER — app khach (package bavia)
//  Dat tai:  lib/models/store_status.dart
//  >> FILE MOI (tao moi)
// ==================================================================

// lib/models/store_status.dart
//
// Trạng thái mở/đóng cửa của quán (lấy từ GET /api/store/status).

class StoreStatus {
  final bool isOpen;
  final String openTime; // 'HH:MM'
  final String closeTime; // 'HH:MM'
  /// null = tự động theo giờ; true = đang ép mở; false = đang tạm đóng.
  final bool? manualOverride;

  const StoreStatus({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.manualOverride,
  });

  factory StoreStatus.fromJson(Map<String, dynamic> json) => StoreStatus(
        isOpen: json['isOpen'] == true,
        openTime: (json['openTime'] ?? '') as String,
        closeTime: (json['closeTime'] ?? '') as String,
        manualOverride: json['manualOverride'] as bool?,
      );

  /// Lý do hiển thị khi đóng.
  String get closedReason => manualOverride == false
      ? 'Quán đang tạm đóng cửa'
      : 'Ngoài giờ mở cửa ($openTime–$closeTime)';

  /// Dòng giờ mở cửa hiển thị.
  String get hoursLabel => '$openTime – $closeTime';
}
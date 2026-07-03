// ============================================================
//  FLUTTER
//  lib/core/config/loyalty_config.dart
//  >> CHEP DE — doi 1 diem = 200d (truoc la 1000d) khi TIEU diem
// ============================================================

// lib/core/config/loyalty_config.dart
//
// Hằng số điểm thưởng dùng để ƯỚC TÍNH mức giảm phía client trước khi đặt đơn.
// Backend mới là nguồn sự thật cuối cùng (tính lại lúc tạo đơn), nhưng để UX
// tốt ta hiển thị ước tính ngay.
//
// ⚠️ CÁC GIÁ TRỊ NÀY PHẢI KHỚP .env BACKEND:
//   LOYALTY_POINT_VALUE         → pointValue
//   LOYALTY_MAX_REDEEM_PERCENT  → maxRedeemPercent
// Nếu đổi bên backend thì sửa ở đây cho khớp, nếu không ước tính sẽ lệch.

class LoyaltyConfig {
  LoyaltyConfig._();

  /// 1 điểm đổi được bao nhiêu VND khi dùng. (Khớp LOYALTY_POINT_VALUE backend.)
  static const int pointValue = 200;

  /// Tối đa được giảm bằng điểm = % của tạm tính.
  static const double maxRedeemPercent = 0.5;

  /// Số điểm tối đa có thể dùng cho đơn này (giới hạn bởi % đơn lẫn số dư).
  static int maxRedeemablePoints(int subtotal, int balance) {
    final byOrder = (subtotal * maxRedeemPercent / pointValue).floor();
    final cap = byOrder < balance ? byOrder : balance;
    return cap < 0 ? 0 : cap;
  }

  /// Quy đổi điểm → tiền giảm (VND).
  static int pointsToValue(int points) => points * pointValue;
}
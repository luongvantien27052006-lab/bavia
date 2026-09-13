// ============================================================
//  FLUTTER — lib/core/config/store_info.dart
//  Nguồn thông tin quán DUY NHẤT (địa chỉ, hotline, Zalo, Facebook, email).
//  Sửa ở ĐÂY là mọi màn (Liên hệ, Thanh toán, ...) tự cập nhật theo.
//  Để trống ('') dòng nào thì nơi dùng sẽ tự ẩn dòng đó.
// ============================================================

class StoreInfo {
  StoreInfo._();

  /// Hotline hỗ trợ. Để '' nếu chưa có.
  static const String hotline = '0325898467';

  /// Link Zalo. Để '' nếu chưa có.
  static const String zaloUrl = 'https://zalo.me/0325898467';

  /// Link Facebook fanpage. Để '' nếu chưa có.
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=100089184953568';

  /// Email hỗ trợ.
  static const String email = 'mongfruits089@gmail.com';

  /// Địa chỉ quán — hiển thị ở màn Liên hệ và mục "Chuyển khoản QR" khi thanh toán.
  static const String address =
      'Số 098, đường Thủy Nguyên, khu đô thị Ecopark, '
      'Xuân Quan, Phụng Công, Hưng Yên';
}

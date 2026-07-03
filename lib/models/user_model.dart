// lib/models/user_model.dart
//
// User trả về trong { user } của /auth/login/phone và /auth/me.
// Shape chưa cố định 100% (backend có thể chưa có name/email), nên parse
// linh hoạt: field thiếu → null/giá trị mặc định, không crash.

import 'json_x.dart';

enum UserRole {
  customer('CUSTOMER'),
  staff('STAFF'),
  admin('ADMIN');

  final String apiValue;
  const UserRole(this.apiValue);

  static UserRole fromApi(String? v) => UserRole.values.firstWhere(
        (r) => r.apiValue == v,
        orElse: () => UserRole.customer,
      );
}

class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final UserRole role;
  final bool isPhoneVerified;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
    this.email,
    this.isPhoneVerified = false,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: JsonX.str(json, ['id', 'userId', 'user_id']),
      phone: JsonX.str(json, ['phone', 'phoneNumber', 'phone_number']),
      name: JsonX.strOrNull(json, ['name', 'fullName', 'full_name']),
      email: JsonX.strOrNull(json, ['email']),
      role: UserRole.fromApi(JsonX.strOrNull(json, ['role'])),
      isPhoneVerified:
          JsonX.boolVal(json, ['is_phone_verified', 'isPhoneVerified']),
      isActive: JsonX.boolVal(json, ['is_active', 'isActive'], fallback: true),
    );
  }

  /// Tên hiển thị: ưu tiên name, không có thì dùng số điện thoại.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : phone;
}

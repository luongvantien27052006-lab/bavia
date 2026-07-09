// ============================================================
//  FLUTTER
//  lib/repositories/auth_repository.dart
//  >> CHEP DE (goi DELETE /auth/me)
// ============================================================

// lib/repositories/auth_repository.dart
//
// Cầu nối giữa Firebase Phone Auth và backend Bavia.
// Luồng: Firebase xác thực OTP → trả idToken → gửi idToken lên
// POST /auth/login/phone → backend cấp accessToken + refreshToken + user.
//
// LƯU Ý: endpoint thật là /auth/login/phone (KHÔNG phải /auth/firebase-login).
// Backend KHÔNG có /auth/logout → logout xử lý phía client (xoá token).

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.I;
  final SecureStorage _storage = SecureStorage.instance;

  /// Đổi Firebase idToken lấy phiên Bavia. Lưu token + trả user.
  Future<UserModel> loginWithFirebaseIdToken(String idToken) async {
    final data = await _api.post(
      '/auth/login/phone',
      data: {'idToken': idToken},
      skipAuth: true,
    );
    final map = Map<String, dynamic>.from(data as Map);

    final accessToken = map['accessToken']?.toString();
    final refreshToken = map['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) {
      throw StateError('Phản hồi đăng nhập thiếu token');
    }
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final userJson = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    return UserModel.fromJson(userJson);
  }

  /// Lấy thông tin user hiện tại (cần token hợp lệ). Backend bọc trong { user }.
  Future<UserModel> fetchMe() async {
    final data = await _api.get('/auth/me');
    final map = Map<String, dynamic>.from(data as Map);
    final userJson = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    return UserModel.fromJson(userJson);
  }

  /// Cập nhật hồ sơ (hiện chỉ tên hiển thị).
  ///
  /// ⚠️ ENDPOINT CHƯA XÁC NHẬN TỪ SOURCE BACKEND. App gọi PATCH /auth/me với
  /// body { name }. Nếu backend chưa có route này, gọi sẽ lỗi 404 và UI báo
  /// "tính năng cần backend hỗ trợ". Khi bạn thêm route PATCH /auth/me (trả về
  /// { user } giống /auth/me) thì màn Hồ sơ sẽ chạy ngay không cần sửa app.
  Future<UserModel> updateProfile({required String name}) async {
    final data = await _api.patch('/auth/me', data: {'name': name});
    final map = Map<String, dynamic>.from(data as Map);
    final userJson = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    return UserModel.fromJson(userJson);
  }

  /// Đăng xuất: backend không có endpoint, chỉ cần xoá token cục bộ.
  /// Xoá tài khoản: gọi DELETE /auth/me rồi xoá token phía client.
  Future<void> deleteAccount() async {
    await _api.delete('/auth/me');
    await _storage.clear();
  }

  Future<void> logout() => _storage.clear();
}
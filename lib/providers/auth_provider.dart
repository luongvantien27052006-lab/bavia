// lib/providers/auth_provider.dart
//
// Quản lý trạng thái phiên đăng nhập toàn app bằng Riverpod Notifier.
//
// 3 trạng thái:
//   unknown        → đang kiểm tra phiên cũ lúc mở app (hiện splash)
//   unauthenticated → chưa đăng nhập (vào màn login)
//   authenticated   → đã đăng nhập (vào app chính)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime/socket_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import 'repository_providers.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;

  const AuthState({required this.status, this.user});

  const AuthState.unknown() : status = AuthStatus.unknown, user = null;
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null;
  const AuthState.authenticated(this.user) : status = AuthStatus.authenticated;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  /// Gọi lúc khởi động: có refresh token cũ → thử lấy /auth/me.
  Future<void> bootstrap() async {
    final hasSession = await SecureStorage.instance.hasSession();
    if (!hasSession) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      state = AuthState.authenticated(user);
      // Mở socket realtime sau khi xác nhận phiên còn hiệu lực.
      await SocketService.instance.connect();
    } catch (_) {
      // Token hỏng/hết hạn và không refresh được → về màn login.
      await SecureStorage.instance.clear();
      state = const AuthState.unauthenticated();
    }
  }

  /// Gọi sau khi đăng nhập Firebase + đổi idToken thành công.
  Future<void> onLoggedIn(UserModel user) async {
    state = AuthState.authenticated(user);
    await SocketService.instance.connect();
  }

  /// Cập nhật user trong state (sau khi sửa hồ sơ thành công).
  void updateUser(UserModel user) {
    if (state.status == AuthStatus.authenticated) {
      state = AuthState.authenticated(user);
    }
  }

  /// Đăng xuất chủ động.
  Future<void> logout() async {
    SocketService.instance.disconnect();
    await ref.read(firebaseAuthServiceProvider).signOut();
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }

  /// Bị backend đẩy ra (refresh token hỏng) — gọi từ ApiClient.onSessionExpired.
  void onSessionExpired() {
    SocketService.instance.disconnect();
    state = const AuthState.unauthenticated();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

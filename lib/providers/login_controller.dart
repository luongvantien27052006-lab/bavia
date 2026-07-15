// ============================================================
//  FLUTTER
//  lib/providers/login_controller.dart
//  >> CHEP DE (giu referralCode + gui kem deviceId)
// ============================================================

// lib/providers/login_controller.dart
//
// Điều khiển luồng đăng nhập OTP 2 bước, tách khỏi UI để màn login chỉ lo
// hiển thị. Giữ bước hiện tại (nhập SĐT / nhập OTP), trạng thái loading,
// lỗi, và verificationId.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';
import '../services/device_id_service.dart';

enum LoginStep { enterPhone, enterOtp }

class LoginState {
  final LoginStep step;
  final String referralCode;
  final bool loading;
  final String? error;
  final String phone; // E.164 đã chuẩn hoá
  final bool otpSent;

  const LoginState({
    this.step = LoginStep.enterPhone,
    this.loading = false,
    this.error,
    this.phone = '',
    this.otpSent = false,
    this.referralCode = '',
  });

  LoginState copyWith({
    LoginStep? step,
    bool? loading,
    Object? error = _sentinel,
    String? phone,
    bool? otpSent,
    String? referralCode,
  }) {
    return LoginState(
      step: step ?? this.step,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      phone: phone ?? this.phone,
      otpSent: otpSent ?? this.otpSent,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  static const _sentinel = Object();
}

class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Bước 1: gửi OTP tới số điện thoại.
  void setReferralCode(String code) {
    state = state.copyWith(referralCode: code);
  }

  Future<void> sendOtp(String rawPhone) async {
    state = state.copyWith(loading: true, error: null, phone: rawPhone);
    final firebase = ref.read(firebaseAuthServiceProvider);

    await firebase.sendOtp(
      phone: rawPhone,
      onCodeSent: (_) {
        state = state.copyWith(
          loading: false,
          step: LoginStep.enterOtp,
          otpSent: true,
        );
      },
      onAutoVerified: (idToken) async {
        // Android tự đọc OTP → đăng nhập luôn.
        await _exchangeAndLogin(idToken);
      },
      onError: (msg) {
        state = state.copyWith(loading: false, error: msg);
      },
    );
  }

  /// Gửi lại OTP (giữ nguyên số đã nhập).
  Future<void> resendOtp() async {
    if (state.phone.isEmpty) return;
    await sendOtp(state.phone);
  }

  /// Bước 2: xác thực 6 số OTP rồi đăng nhập backend.
  Future<void> verifyOtp(String code) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final idToken =
          await ref.read(firebaseAuthServiceProvider).verifyOtp(code);
      await _exchangeAndLogin(idToken);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Đổi idToken lấy phiên Bavia + cập nhật auth state toàn app.
  Future<void> _exchangeAndLogin(String idToken) async {
    try {
      final deviceId = await DeviceIdService.instance.get();
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithFirebaseIdToken(
            idToken,
            referralCode: state.referralCode,
            deviceId: deviceId,
          );
      await ref.read(authProvider.notifier).onLoggedIn(user);
      // auth state đổi sang authenticated → router tự chuyển vào app.
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Quay lại bước nhập số điện thoại.
  void backToPhone() {
    state = state.copyWith(step: LoginStep.enterPhone, error: null);
  }
}

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginState>(
        LoginController.new);
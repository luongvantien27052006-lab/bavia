// lib/services/firebase_auth_service.dart
//
// Bọc Firebase Phone Auth thành 2 bước rõ ràng cho UI:
//   1. sendOtp(phone)  → Firebase gửi SMS, trả verificationId qua callback.
//   2. verifyOtp(code) → tạo credential, đăng nhập Firebase, lấy idToken.
//
// idToken sau đó được AuthRepository đổi lấy phiên Bavia.

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/formatters.dart';

class OtpSendResult {
  final String? verificationId; // null nếu auto-verify (Android)
  final String? autoIdToken; // có giá trị nếu Android tự verify xong
  final String? error;

  const OtpSendResult({this.verificationId, this.autoIdToken, this.error});
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  /// Gửi OTP. Trả về verificationId qua callback codeSent.
  /// Trên Android có thể auto-verify (không cần nhập tay) → onAutoVerified.
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String message) onError,
    int? resendToken,
  }) async {
    final e164 = Formatters.toE164(phone);

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android: hệ thống tự đọc OTP và verify.
        try {
          final cred = await _auth.signInWithCredential(credential);
          final idToken = await cred.user?.getIdToken();
          if (idToken != null) onAutoVerified(idToken);
        } catch (e) {
          onError(_mapError(e));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapError(e));
      },
      codeSent: (String verificationId, int? token) {
        _verificationId = verificationId;
        _resendToken = token;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  int? get resendToken => _resendToken;

  /// Nhập 6 số → đăng nhập Firebase → trả idToken cho backend.
  Future<String> verifyOtp(String smsCode) async {
    final vid = _verificationId;
    if (vid == null) {
      throw StateError('Chưa gửi OTP. Vui lòng thử lại.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: vid,
      smsCode: smsCode.trim(),
    );
    final result = await _auth.signInWithCredential(credential);
    final idToken = await result.user?.getIdToken();
    if (idToken == null) {
      throw StateError('Không lấy được mã xác thực từ Firebase.');
    }
    return idToken;
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(Object e) {
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-phone-number' => 'Số điện thoại không hợp lệ.',
        'invalid-verification-code' => 'Mã OTP không đúng.',
        'session-expired' => 'Mã OTP đã hết hạn. Vui lòng gửi lại.',
        'too-many-requests' =>
          'Bạn yêu cầu quá nhiều lần. Vui lòng thử lại sau.',
        'quota-exceeded' => 'Hệ thống tạm quá tải. Thử lại sau ít phút.',
        _ => e.message ?? 'Xác thực thất bại. Vui lòng thử lại.',
      };
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}

// ============================================================
//  lib/services/firebase_auth_service.dart
//  >> BẢN CHẨN ĐOÁN: hiện RÕ mã lỗi Firebase (e.code) ra màn hình,
//     để biết chính xác vì sao "Gửi mã OTP" thất bại trên iOS.
//  Sau khi lấy được mã, đổi lại bản thường (message thân thiện) là được.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/formatters.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String message) onError,
    int? resendToken,
  }) async {
    final e164 = Formatters.toE164(phone);
    debugPrint('☎️ verifyPhoneNumber cho: $e164');

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          final idToken = await cred.user?.getIdToken();
          if (idToken != null) onAutoVerified(idToken);
        } catch (e) {
          onError(_diag(e));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        // In đầy đủ ra console (đọc được qua 3uTools) + hiện lên UI.
        debugPrint('❌ verifyPhoneNumber FAILED');
        debugPrint('   code    = ${e.code}');
        debugPrint('   message = ${e.message}');
        debugPrint('   details = ${e.toString()}');
        onError(_diag(e));
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

  /// CHẨN ĐOÁN: luôn kèm mã lỗi để nhìn thấy nguyên nhân thật.
  String _diag(Object e) {
    if (e is FirebaseAuthException) {
      return 'MÃ LỖI: [${e.code}]\n${e.message ?? ''}';
    }
    return 'Lỗi khác: $e';
  }
}
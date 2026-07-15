// ============================================================
//  FLUTTER
//  lib/screens/auth/login_screen.dart
//  >> CHEP DE (o 'Ma gioi thieu (neu co)')
// ============================================================

// ============================================================
//  FLUTTER
//  lib/screens/auth/login_screen.dart
//  >> CHEP DE (nen diu + form tren the trang, do choi)
// ============================================================

// lib/screens/auth/login_screen.dart
//
// Màn đăng nhập 2 bước: nhập SĐT → nhập 6 số OTP.
// Nền dịu (ảnh assets/images/auth_bg.jpg nếu có, không thì gradient nhạt) +
// form nằm trên THẺ TRẮNG cho đỡ chói, dễ đọc.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/login_controller.dart';
import '../../utils/formatters.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();
  static const _otpLength = 6;
  final _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocus = List.generate(_otpLength, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _submitPhone() {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại hợp lệ')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(loginControllerProvider.notifier).sendOtp(phone);
  }

  void _submitOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 số')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(loginControllerProvider.notifier).verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    // Đăng nhập xong (được mở dạng push từ khách) → tự đóng, quay lại app.
    ref.listen(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    // Hiện lỗi qua SnackBar khi error đổi.
    ref.listen(loginControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.delivery,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Ảnh nền: dùng assets/images/auth_bg.jpg nếu có; không thì gradient dịu.
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF1E8), Color(0xFFFCE3D6)],
                  ),
                ),
              ),
            ),
          ),
          // Lớp phủ sáng nhẹ để đỡ chói + chữ trên thẻ dễ đọc.
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.28)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _logo(),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: state.step == LoginStep.enterPhone
                            ? _phoneForm(state)
                            : _otpForm(state),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.coffee.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_cafe_rounded,
              color: AppColors.coffee, size: 44),
        ),
        const SizedBox(height: 14),
        const Text(
          'Mọng Fruits',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Đặt món & tích điểm mỗi ngày',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ─── Bước 1: nhập số điện thoại ──────────────────────────────────────
  Widget _phoneForm(LoginState state) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Số điện thoại',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: !state.loading,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: '09xx xxx xxx',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          onSubmitted: (_) => _submitPhone(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: state.loading ? null : _submitPhone,
          child: state.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Text('Gửi mã OTP'),
        ),
      ],
    );
  }

  // ─── Bước 2: nhập OTP ────────────────────────────────────────────────
  Widget _otpForm(LoginState state) {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Xác thực OTP',
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'Mã 6 số vừa gửi tới ${Formatters.prettyPhone(Formatters.toE164(state.phone))}',
          style: const TextStyle(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(_otpLength, (i) {
            return Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AspectRatio(
                  aspectRatio: 0.78,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocus[i],
                    enabled: !state.loading,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppColors.cream,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.coffee.withOpacity(0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.coffee, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < _otpLength - 1) {
                        _otpFocus[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _otpFocus[i - 1].requestFocus();
                      }
                      if (i == _otpLength - 1 && v.isNotEmpty) {
                        final code =
                            _otpControllers.map((c) => c.text).join();
                        if (code.length == _otpLength) _submitOtp();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _referralController,
          enabled: !state.loading,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) =>
              ref.read(loginControllerProvider.notifier).setReferralCode(v),
          decoration: const InputDecoration(
            labelText: 'Mã giới thiệu (nếu có)',
            hintText: 'VD: MONG-ABC123',
            prefixIcon: Icon(Icons.card_giftcard_rounded),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nhập mã của bạn bè để họ nhận thưởng khi bạn dùng app.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: state.loading ? null : _submitOtp,
          child: state.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Text('Đăng nhập'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: state.loading
                  ? null
                  : () =>
                      ref.read(loginControllerProvider.notifier).backToPhone(),
              child: const Text('Đổi số',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            const Text('•', style: TextStyle(color: AppColors.textMuted)),
            TextButton(
              onPressed: state.loading
                  ? null
                  : () =>
                      ref.read(loginControllerProvider.notifier).resendOtp(),
              child: const Text('Gửi lại mã',
                  style: TextStyle(
                      color: AppColors.coffee, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}
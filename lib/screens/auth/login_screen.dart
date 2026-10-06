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
import '../../widgets/aurora_background.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/stage.dart';
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

    // Android tự đọc được OTP → ĐIỀN sẵn vào 6 ô (KHÔNG tự đăng nhập).
    // Khách xem lại, kịp nhập mã giới thiệu, rồi TỰ bấm "Đăng nhập".
    ref.listen<String?>(
      loginControllerProvider.select((s) => s.autoFilledCode),
      (prev, next) {
        if (next != null && next.length == _otpLength) {
          for (int i = 0; i < _otpLength; i++) {
            _otpControllers[i].text = next[i];
          }
          FocusScope.of(context).unfocus();
        }
      },
    );

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

    final canPop = Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: stageOverlay,
      child: Scaffold(
        backgroundColor: DrinkTint.stageInk,
        body: AuroraBackground(
          tint: DrinkTint.fallback,
          base: DrinkTint.stageInk,
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
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
                        StageGlass(
                          radius: 26,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
              if (canPop)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 12,
                  child: StageIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Đóng',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: DrinkTint.fallback.withValues(alpha: 0.5),
                  blurRadius: 30),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: St.fill(0.12),
                child:  Icon(Icons.local_drink_rounded,
                    color: St.fg(), size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mọng Fruits',
          style: TextStyle(
            color: St.fg(),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đặt món & tích điểm mỗi ngày',
          style: TextStyle(color: St.fg(0.7)),
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
        Text('Số điện thoại',
            style: TextStyle(
                color: St.fg(), fontWeight: FontWeight.w700)),
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
        StageButton(
          label: 'Gửi mã OTP',
          icon: Icons.sms_rounded,
          white: true,
          loading: state.loading,
          onTap: state.loading ? null : _submitPhone,
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
        Text('Xác thực OTP',
            style: TextStyle(
                color: St.fg(),
                fontSize: 20,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'Mã 6 số vừa gửi tới ${Formatters.prettyPhone(Formatters.toE164(state.phone))}',
          style: TextStyle(color: St.fg(0.7)),
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: St.fg(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: St.fill(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: St.line(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                             BorderSide(color: St.line(1), width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < _otpLength - 1) {
                        _otpFocus[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _otpFocus[i - 1].requestFocus();
                      }
                      // KHÔNG tự submit khi đủ 6 số — khách tự bấm "Đăng nhập".
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
        Text(
          'Nhập mã của bạn bè để họ nhận thưởng khi bạn dùng app.',
          style: TextStyle(fontSize: 12, color: St.fg(0.6)),
        ),
        const SizedBox(height: 22),
        StageButton(
          label: 'Đăng nhập',
          icon: Icons.login_rounded,
          white: true,
          loading: state.loading,
          onTap: state.loading ? null : _submitOtp,
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
              child: Text('Đổi số',
                  style: TextStyle(color: St.fg(0.7))),
            ),
            Text('•', style: TextStyle(color: St.fg(0.7))),
            TextButton(
              onPressed: state.loading
                  ? null
                  : () =>
                      ref.read(loginControllerProvider.notifier).resendOtp(),
              child:  Text('Gửi lại mã',
                  style: TextStyle(
                      color: St.fg(), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}
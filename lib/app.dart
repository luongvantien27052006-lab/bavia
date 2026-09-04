// ============================================================
//  FLUTTER
//  lib/app.dart
//  >> CHEP DE (navigatorKey + mo chi tiet don khi bam thong bao)
// ============================================================

// ============================================================
//  FLUTTER
//  lib/app.dart
//  >> CHEP DE (bo ep dang nhap: khach vao thang app)
// ============================================================

// lib/app.dart
//
// Widget gốc. Điều hướng theo trạng thái đăng nhập:
//   unknown        → SplashScreen (đang bootstrap)
//   unauthenticated → LoginScreen
//   authenticated   → MainShell (app chính)
//
// Cũng nối ApiClient.onSessionExpired → đẩy auth state về unauthenticated
// khi backend từ chối refresh token.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_shell.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/theme_switcher.dart';
import 'services/push_service.dart';

class BaviaApp extends ConsumerStatefulWidget {
  const BaviaApp({super.key});

  @override
  ConsumerState<BaviaApp> createState() => _BaviaAppState();
}

class _BaviaAppState extends ConsumerState<BaviaApp> {
  @override
  void initState() {
    super.initState();
    // Khi token hết hạn không refresh được → về màn đăng nhập.
    ApiClient.I.onSessionExpired = () {
      ref.read(authProvider.notifier).onSessionExpired();
    };

    // Bấm vào thông báo đơn hàng → mở màn chi tiết đơn.
    PushService.instance.onOpenOrder = _openOrder;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.instance.flushPending();
    });
    // Kiểm tra phiên cũ sau frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  void _openOrder(String orderId) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      PushService.instance.pendingOrderId = orderId;
      return;
    }
    // Chưa đăng nhập thì bỏ qua (không có đơn để xem).
    if (ref.read(authProvider).user == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    final mode = ref.watch(themeModeProvider);
    final _dark = mode == ThemeMode.dark;
    AppColors.dark = _dark;
    // Thanh điều hướng + trạng thái hệ thống đổi theo chế độ (khớp nền gradient).
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor:
          _dark ? const Color(0xFF16110E) : const Color(0xFFDFF3EE),
      systemNavigationBarIconBrightness:
          _dark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Mọng Fruits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // Đổi màu nền/theme tức thì bên dưới; độ mượt do ThemeSwitcher
      // (chụp ảnh cũ rồi mờ dần) đảm nhiệm -> tránh animate 2 lớp.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ColoredBox(
        // Nền theo theme (cream/tối) sau mọi màn -> vùng app bar/nền trong suốt
        // KHÔNG còn lộ màu đen; tự đổi theo chế độ sáng/tối.
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ThemeSwitcher(child: child ?? const SizedBox.shrink()),
      ),
      home: switch (status) {
        AuthStatus.unknown => const SplashScreen(),
        // Khách chưa đăng nhập vẫn vào thẳng app;
        // chỉ bắt đăng nhập khi bấm nút hoặc khi đặt đơn.
        _ => const MainShell(),
      },
    );
  }
}
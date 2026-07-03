// ============================================================
//  FLUTTER
//  lib/app.dart
//  >> CHEP DE (title app -> Mong Fruits)
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';

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
    // Kiểm tra phiên cũ sau frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;

    return MaterialApp(
      title: 'Mọng Fruits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (status) {
        AuthStatus.unknown => const SplashScreen(),
        // Khách chưa đăng nhập vẫn vào thẳng app;
        // chỉ bắt đăng nhập khi bấm nút hoặc khi đặt đơn.
        _ => const MainShell(),
      },
    );
  }
}
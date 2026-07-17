// ============================================================
//  FLUTTER  —  BAN DAY DU (co PushService)
//  lib/main.dart
//  >> CHEP DE (firebase_options + try/catch + push init)
// ============================================================

// lib/main.dart
//
// Điểm khởi động: Firebase → Push → ApiClient → date locale → runApp.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nếu có lỗi giao diện, hiện nội dung lỗi ra màn hình thay vì màn trắng
  // (dễ chụp gửi đi khi gỡ lỗi).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'LỖI GIAO DIỆN:\n\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ),
    );
  };

  // Khởi tạo Firebase bằng options nhúng trong code (firebase_options.dart)
  // -> chạy đúng trên CẢ iOS lẫn Android, không phụ thuộc GoogleService-Info.plist.
  // Bọc try/catch: nếu Firebase lỗi thì app VẪN mở (không treo màn trắng),
  // chỉ là tính năng cần Firebase (OTP/push) tạm thời không dùng được.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushService.instance.init();
  } catch (e, st) {
    debugPrint('Khởi tạo Firebase lỗi: $e\n$st');
  }

  // Khởi tạo HTTP client (đọc baseUrl từ ApiConfig).
  ApiClient.I.init();

  // Locale cho định dạng tiền/ngày tiếng Việt.
  await initializeDateFormatting('vi_VN', null);

  runApp(const ProviderScope(child: BaviaApp()));
}
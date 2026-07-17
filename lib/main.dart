// ============================================================
//  FLUTTER — lib/main.dart  (BẢN GIA CỐ v2 — SỬA lỗi [core/no-app])
//
//  Thứ tự ĐÚNG:
//    1) Firebase.initializeApp()  -> PHẢI xong TRƯỚC runApp, vì cây widget
//       (PushService/FirebaseMessaging) dùng Firebase NGAY khi khởi tạo.
//       Firebase KHÔNG treo (màn chẩn đoán đã xác nhận "ok").
//    2) runApp()
//    3) PushService.init()        -> ĐÂY mới là thứ treo trên iOS
//       (getInitialMessage đợi APNS). Đẩy RIÊNG nó xuống chạy nền + timeout,
//       nên không bao giờ chặn giao diện.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';

void main() {
  // Bắt cả lỗi async ngoài cây widget.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Widget lỗi bọc Directionality -> hiện được chữ đỏ kể cả lỗi tầng cao,
    // thay vì rơi về màn trắng.
    ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
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
          ),
        );

    // Init đồng bộ, an toàn.
    ApiClient.I.init();

    // Locale tiền/ngày tiếng Việt (nhanh, an toàn) — cây widget cần nó.
    try {
      await initializeDateFormatting('vi_VN', null);
    } catch (e) {
      debugPrint('initializeDateFormatting lỗi: $e');
    }

    // >>> Firebase PHẢI khởi tạo XONG trước runApp. Nó không treo;
    //     vẫn bọc try/catch để nếu có lỗi thì app vẫn mở (chỉ mất tính năng
    //     phụ thuộc Firebase), không màn trắng.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('Khởi tạo Firebase lỗi: $e\n$st');
    }

    // Firebase đã sẵn sàng -> chạy app.
    runApp(const ProviderScope(child: BaviaApp()));

    // CHỈ Push init chạy nền (thứ duy nhất có thể treo trên iOS).
    // push_service.dart đã có timeout ở getInitialMessage nên tự thoát.
    unawaited(_initPush());
  }, (error, stack) {
    debugPrint('❌ LỖI KHÔNG BẮT ĐƯỢC (zone): $error\n$stack');
  });
}

Future<void> _initPush() async {
  try {
    await PushService.instance.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('PushService.init lỗi/timeout: $e');
  }
}
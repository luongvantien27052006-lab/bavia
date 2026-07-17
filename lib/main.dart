// ============================================================
//  FLUTTER — lib/main.dart  (BẢN GIA CỐ CHỐNG MÀN TRẮNG iOS)
//
//  Nguyên tắc: runApp() PHẢI được gọi và KHÔNG BAO GIỜ bị chặn bởi
//  Firebase/Push. Mọi init phụ thuộc mạng/native chạy NỀN, có timeout.
//  Nhờ vậy nếu có gì treo, bạn thấy GIAO DIỆN (hoặc chữ đỏ báo lỗi),
//  chứ không phải màn trắng.
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
  // runZonedGuarded bắt cả những lỗi async xảy ra NGOÀI cây widget
  // (những lỗi mà ErrorWidget.builder không thể thấy).
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('>>> BOOT 1: binding ready');

    // Widget lỗi được BỌC Directionality để hiển thị được ngay cả khi
    // lỗi xảy ra PHÍA TRÊN MaterialApp (nếu không, Text sẽ tự văng ->
    // rơi về màn trắng).
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
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
    };

    // Init ĐỒNG BỘ, an toàn, nhanh — không gọi mạng, không đụng native.
    ApiClient.I.init();
    debugPrint('>>> BOOT 2: ApiClient ready');

    // Locale tiền/ngày tiếng Việt: đọc dữ liệu đóng gói sẵn, không treo.
    try {
      await initializeDateFormatting('vi_VN', null);
    } catch (e) {
      debugPrint('initializeDateFormatting lỗi: $e');
    }
    debugPrint('>>> BOOT 3: date locale ready');

    // >>> CHẠY APP NGAY. Không await Firebase/Push ở đây.
    runApp(const ProviderScope(child: BaviaApp()));
    debugPrint('>>> BOOT 4: REACHED runApp  ✅');

    // Firebase + Push chạy NỀN, có timeout -> không bao giờ chặn giao diện.
    unawaited(_initFirebaseAndPush());
  }, (error, stack) {
    // Nếu thấy dòng này trong Console mà KHÔNG thấy "BOOT 4",
    // tức là có lỗi async chặn khởi động trước runApp.
    debugPrint('❌ LỖI KHÔNG BẮT ĐƯỢC (zone): $error\n$stack');
  });
}

/// Firebase/Messaging init tách riêng, có giới hạn thời gian.
/// Nếu treo/timeout: app VẪN chạy, chỉ là OTP/push tạm thời chưa dùng được.
Future<void> _initFirebaseAndPush() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    debugPrint('>>> Firebase.initializeApp OK');

    await PushService.instance.init().timeout(const Duration(seconds: 8));
    debugPrint('>>> PushService.init OK');
  } on TimeoutException {
    debugPrint('⏱️ Firebase/Push init QUÁ THỜI GIAN -> bỏ qua (app vẫn chạy).');
  } catch (e, st) {
    debugPrint('Khởi tạo Firebase lỗi: $e\n$st');
  }
}
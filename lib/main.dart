// lib/main.dart
//
// Điểm khởi động: Firebase → ApiClient → date locale → runApp.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/network/api_client.dart';
// import 'firebase_options.dart'; // tạo bằng `flutterfire configure`

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TẠM THỜI ĐỂ GỠ LỖI: thay vì màn trắng, hiện thẳng nội dung lỗi ra màn hình
  // để dễ chụp gửi đi. Khi xong có thể xoá block này.
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

  // Khởi tạo Firebase. Sau khi chạy `flutterfire configure`, mở dòng dưới
  // và truyền options để chắc chắn đúng project:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // Khởi tạo HTTP client (đọc baseUrl từ ApiConfig).
  ApiClient.I.init();

  // Locale cho định dạng tiền/ngày tiếng Việt.
  await initializeDateFormatting('vi_VN', null);

  runApp(const ProviderScope(child: BaviaApp()));
}

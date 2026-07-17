// ============================================================
//  lib/main.dart  — BẢN CHẨN ĐOÁN (in log RA MÀN HÌNH điện thoại)
//
//  Mục đích: KHÔNG cần Mac, không cần console. Điện thoại tự hiện
//  từng bước khởi động + lỗi. Cách đọc kết quả:
//
//   • Thấy MÀN HÌNH TỐI kèm danh sách log  -> Dart/Flutter CHẠY TỐT.
//     Nhìn xuống bước nào ghi "TIMEOUT" hoặc "LỖI" -> đó là thủ phạm
//     làm treo khởi động (thường là Firebase/Push).
//
//   • Vẫn TRẮNG TINH (không thấy màn tối này) -> lỗi nằm ở tầng NATIVE
//     iOS, không phải code Dart. Xem hướng dẫn đọc log thiết bị / dựng
//     lại iOS trên Windows mà mình gửi kèm.
//
//  Dùng xong, thay lại bằng main.dart bản gia cố (runApp-first) để dùng thật.
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

// Log hiển thị TRÊN MÀN HÌNH.
final ValueNotifier<List<String>> _bootLog = ValueNotifier<List<String>>([]);
void _log(String m) {
  _bootLog.value = [..._bootLog.value, m];
  debugPrint(m); // đồng thời in ra console nếu có (idevicesyslog trên Windows)
}

void main() {
  // Bắt cả lỗi async ngoài cây widget.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Widget lỗi bọc Directionality để hiện được kể cả lỗi tầng cao.
    ErrorWidget.builder = (d) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.white,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Text('LỖI GIAO DIỆN:\n\n${d.exceptionAsString()}',
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),
          ),
        );

    // >>> VẼ MÀN CHẨN ĐOÁN NGAY. Nếu bạn ĐỌC ĐƯỢC nó -> runApp OK.
    runApp(const _DiagnosticApp());
    _log('✅ runApp đã chạy — Dart/Flutter OK.');

    _log('• ApiClient.init …');
    ApiClient.I.init();
    _log('  ok');

    _log('• initializeDateFormatting(vi_VN) …');
    try {
      await initializeDateFormatting('vi_VN', null);
      _log('  ok');
    } catch (e) {
      _log('  LỖI: $e');
    }

    _log('• Firebase.initializeApp (giới hạn 8s) …');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
      _log('  ok');
    } on TimeoutException {
      _log('  ⏱️ TIMEOUT — RẤT CÓ THỂ đây là thủ phạm treo khởi động!');
    } catch (e) {
      _log('  LỖI: $e');
    }

    _log('• PushService.init (giới hạn 8s) …');
    try {
      await PushService.instance.init().timeout(const Duration(seconds: 8));
      _log('  ok');
    } on TimeoutException {
      _log('  ⏱️ TIMEOUT — thủ phạm treo khởi động (thường do thiếu '
          'entitlement Push / APNS)!');
    } catch (e) {
      _log('  LỖI: $e');
    }

    _log('———');
    _log('XONG init. Bấm "MỞ APP THẬT" để vào app.');
  }, (e, st) {
    _log('❌ LỖI ZONE (async): $e');
  });
}

class _DiagnosticApp extends StatelessWidget {
  const _DiagnosticApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0E1116), // TỐI để phân biệt với bug trắng
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          foregroundColor: Colors.white,
          title: const Text('Chẩn đoán khởi động iOS'),
          centerTitle: false,
        ),
        body: SafeArea(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _bootLog,
            builder: (context, log, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final line in log)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: (line.contains('LỖI') ||
                                  line.contains('TIMEOUT') ||
                                  line.contains('❌'))
                              ? const Color(0xFFFF7B72)
                              : const Color(0xFFC9D1D9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () =>
                        runApp(const ProviderScope(child: BaviaApp())),
                    child: const Text('MỞ APP THẬT'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
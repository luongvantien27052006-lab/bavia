// ============================================================
//  FLUTTER — lib/main.dart  (BAN PRODUCTION - dung cho SO THAT)
//  KHONG co flag test. Firebase khoi tao TRUOC runApp; chi Push
//  chay nen co timeout. Dung ban nay khi da lam xong APNs/profile.
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
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.white,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Text(
                  'LOI GIAO DIEN:\n\n${details.exceptionAsString()}',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
          ),
        );

    ApiClient.I.init();

    try {
      await initializeDateFormatting('vi_VN', null);
    } catch (e) {
      debugPrint('initializeDateFormatting loi: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('Khoi tao Firebase loi: $e\n$st');
    }

    runApp(const ProviderScope(child: BaviaApp()));

    unawaited(_initPush());
  }, (error, stack) {
    debugPrint('LOI KHONG BAT DUOC (zone): $error\n$stack');
  });
}

Future<void> _initPush() async {
  try {
    await PushService.instance.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('PushService.init loi/timeout: $e');
  }
}
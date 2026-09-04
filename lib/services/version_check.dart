// lib/services/version_check.dart
//
// Lấy cấu hình phiên bản (GET /app-config), so với phiên bản app hiện tại:
//  - current < minVersion   → BẮT BUỘC cập nhật (màn chặn).
//  - current < latestVersion → GỢI Ý cập nhật (dialog, 1 lần/phiên).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/network/api_client.dart';
import '../models/app_version_config.dart';
import '../screens/update/update_screen.dart';

bool _softShownThisSession = false;

/// So sánh "x.y.z" (bỏ qua build sau dấu +). >0 nếu a>b, <0 nếu a<b.
int compareVersion(String a, String b) {
  List<int> parse(String v) => v
      .split('+')
      .first
      .split('.')
      .map((e) => int.tryParse(e.trim()) ?? 0)
      .toList();
  final pa = parse(a);
  final pb = parse(b);
  for (int i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

Future<AppVersionConfig?> _fetchConfig() async {
  try {
    final data = await ApiClient.I.get('/app-config', skipAuth: true);
    if (data is Map) {
      return AppVersionConfig.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  } catch (_) {
    return null; // lỗi mạng → bỏ qua, không chặn app
  }
}

/// Kiểm tra & hiển thị cập nhật nếu cần. Gọi 1 lần khi app khởi động.
Future<void> checkForUpdate(BuildContext context) async {
  final config = await _fetchConfig();
  if (config == null) return;

  String current;
  try {
    final info = await PackageInfo.fromPlatform();
    current = info.version; // ví dụ "1.2.3"
  } catch (_) {
    return;
  }

  final storeUrl = Platform.isIOS ? config.iosUrl : config.androidUrl;
  if (!context.mounted) return;

  if (compareVersion(current, config.minVersion) < 0) {
    // BẮT BUỘC — đẩy màn chặn trên navigator gốc.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => UpdateScreen(config: config, storeUrl: storeUrl),
      ),
    );
  } else if (compareVersion(current, config.latestVersion) < 0 &&
      !_softShownThisSession) {
    // GỢI Ý — dialog 1 lần mỗi phiên (không làm phiền).
    _softShownThisSession = true;
    showDialog(
      context: context,
      builder: (_) => UpdateDialog(config: config, storeUrl: storeUrl),
    );
  }
}
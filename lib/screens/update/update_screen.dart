// lib/screens/update/update_screen.dart
//
// Màn BẮT BUỘC cập nhật (chặn back) + Dialog GỢI Ý cập nhật (bỏ qua được).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_version_config.dart';

Future<void> openStore(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Màn bắt buộc cập nhật — không thể thoát cho tới khi cập nhật.
class UpdateScreen extends StatelessWidget {
  final AppVersionConfig config;
  final String storeUrl;
  const UpdateScreen({
    super.key,
    required this.config,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // chặn nút back -> buộc cập nhật
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.coffee, AppColors.coffeeDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.coffee.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),
                Text('Đã có phiên bản mới!',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
                const SizedBox(height: 12),
                Text(config.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textMuted)),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.hot.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_rounded, color: AppColors.hot, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                            'Cần cập nhật để tiếp tục sử dụng ứng dụng.',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => openStore(storeUrl),
                    icon: const Icon(Icons.system_update_rounded),
                    label: const Text('Cập nhật ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffee,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog gợi ý cập nhật (không bắt buộc) — có thể "Để sau".
class UpdateDialog extends StatelessWidget {
  final AppVersionConfig config;
  final String storeUrl;
  const UpdateDialog({
    super.key,
    required this.config,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.coffee.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.system_update_rounded,
                  color: AppColors.coffee, size: 34),
            ),
            const SizedBox(height: 16),
            Text('Có bản cập nhật mới',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(config.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Để sau'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openStore(storeUrl);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coffee,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Cập nhật'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
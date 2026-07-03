// lib/screens/scan/scan_screen.dart
//
// Tab Scan — quét QR tại quầy (sẽ hoàn thiện sau). Hiện là placeholder gọn.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 72, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text('Quét mã QR tại quầy',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Tính năng sẽ sớm có mặt.',
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

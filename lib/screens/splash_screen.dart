// ============================================================
//  FLUTTER
//  lib/screens/splash_screen.dart
//  >> CHEP DE (ten -> Mong Fruits)
// ============================================================

// lib/screens/splash_screen.dart
//
// Màn hiển thị trong lúc app kiểm tra phiên đăng nhập cũ (bootstrap).

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.coffeeDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_cafe_rounded,
                  color: Colors.white, size: 46),
            ),
            const SizedBox(height: 20),
            const Text('Mọng Fruits',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
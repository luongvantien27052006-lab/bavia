// ============================================================
//  FLUTTER
//  lib/screens/splash_screen.dart
//  >> CHEP DE — splash mới: logo thật + nền kem sang trọng + animation.
// ============================================================

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Màu thương hiệu lấy từ logo (đỏ mận + xanh lá).
    const brandRed = Color(0xFF9E2B25);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF5), // kem sáng
              Color(0xFFFDF2E7), // kem ấm
              Color(0xFFFBEADB), // kem đào nhạt
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Logo giữa màn + hiệu ứng mờ dần + phóng nhẹ.
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: w * 0.60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Loading + tagline ở dưới.
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 52),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(brandRed),
                            backgroundColor: brandRed.withOpacity(0.12),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Tươi ngon mỗi ngày',
                          style: TextStyle(
                            color: brandRed.withOpacity(0.75),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
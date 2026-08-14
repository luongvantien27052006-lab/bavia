// ============================================================
//  FLUTTER — lib/widgets/theme_switcher.dart
//  Chuyen Sang/Toi MUOT bang crossfade toan man:
//   1. chup anh man hinh hien tai (mau cu)
//   2. doi theme -> noi dung ben duoi ve mau moi
//   3. mo dan lop anh cu di -> lo lop moi
//  Cach nay animate deu ca man, khong phu thuoc mau lay tu ThemeData
//  hay tu AppColors.
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ThemeSwitcher extends StatefulWidget {
  final Widget child;
  const ThemeSwitcher({super.key, required this.child});

  /// Chay [applyChange] (doi theme) kem hieu ung crossfade.
  /// Tu dong tim ThemeSwitcher gan nhat; neu khong co thi doi thang.
  static void run(BuildContext context, VoidCallback applyChange) {
    final state = context.findAncestorStateOfType<ThemeSwitcherState>();
    if (state != null) {
      state.animateToTheme(applyChange);
    } else {
      applyChange();
    }
  }

  @override
  State<ThemeSwitcher> createState() => ThemeSwitcherState();
}

class ThemeSwitcherState extends State<ThemeSwitcher>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  ui.Image? _snapshot;

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<void> animateToTheme(VoidCallback applyChange) async {
    if (_controller.isAnimating) {
      applyChange();
      return;
    }

    ui.Image? image;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        image = await boundary.toImage(pixelRatio: dpr);
      }
    } catch (_) {
      image = null;
    }

    if (image == null) {
      applyChange(); // khong chup duoc -> doi thang
      return;
    }

    setState(() => _snapshot = image);
    applyChange(); // doi theme: noi dung ben duoi doi mau
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _snapshot?.dispose();
        _snapshot = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _controller.drive(
                  Tween<double>(begin: 1, end: 0)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: RawImage(image: _snapshot, fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }
}
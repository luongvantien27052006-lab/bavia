// ============================================================
//  FLUTTER — lib/widgets/empty_state.dart  (MỚI)
//  Màn trống đẹp: icon lớn + tiêu đề + mô tả + nút (tuỳ chọn).
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.coffee;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.withOpacity(0.18), c.withOpacity(0.06)],
                ),
              ),
              child: Icon(icon, size: 60, color: c),
            ),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMuted, height: 1.45, fontSize: 13.5)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
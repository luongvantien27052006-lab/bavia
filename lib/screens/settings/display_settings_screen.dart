// lib/screens/settings/display_settings_screen.dart
//
// Giao diện: Chế độ tối + Hiệu ứng kính + Ảnh hiện dần + Màu nền (chế độ sáng).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/display_settings_provider.dart';

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final s = ref.watch(displaySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Giao diện',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Chế độ'),
          _switchTile(
            icon: Icons.dark_mode_rounded,
            color: AppColors.coffee,
            title: 'Chế độ tối',
            subtitle: 'Nền tối, dịu mắt khi dùng ban đêm',
            value: isDark,
            onChanged: (v) => ref
                .read(themeModeProvider.notifier)
                .setMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
          const SizedBox(height: 18),
          _sectionHeader('Hiệu ứng'),
          _switchTile(
            icon: Icons.blur_on_rounded,
            color: AppColors.hot,
            title: 'Hiệu ứng kính',
            subtitle: 'Làm mờ nền sau các thẻ (tắt để chạy nhẹ hơn)',
            value: s.glass,
            onChanged: (v) =>
                ref.read(displaySettingsProvider.notifier).setGlass(v),
          ),
          _switchTile(
            icon: Icons.image_rounded,
            color: AppColors.success,
            title: 'Ảnh hiện dần',
            subtitle: 'Ảnh món mờ dần khi tải xong (tắt để hiện ngay)',
            value: s.imageFade,
            onChanged: (v) =>
                ref.read(displaySettingsProvider.notifier).setImageFade(v),
          ),
          _switchTile(
            icon: Icons.gradient_rounded,
            color: AppColors.pickup,
            title: 'Màu nền (chế độ sáng)',
            subtitle: 'Nền chuyển màu ở chế độ sáng (tắt để nền phẳng)',
            value: s.colorBg,
            onChanged: (v) =>
                ref.read(displaySettingsProvider.notifier).setColorBg(v),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('Tuỳ chỉnh giao diện theo ý bạn 🎨',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.3)),
      );

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 23),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ),
    );
  }
}
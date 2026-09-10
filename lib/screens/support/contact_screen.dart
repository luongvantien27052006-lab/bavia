// lib/screens/support/contact_screen.dart
//
// Trang "Liên hệ hỗ trợ" — hotline, Zalo, Facebook, email, địa chỉ quán.
// Bấm vào từng mục sẽ mở app tương ứng. Để trống mục nào -> tự ẩn mục đó.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // ⚙️ THÔNG TIN LIÊN HỆ — điền vào đây (để trống dòng nào thì dòng đó tự ẩn).
  static const String hotline = ''; // VD: '0338316893'
  static const String zaloUrl = ''; // VD: 'https://zalo.me/0338316893'
  static const String facebookUrl = 'https://www.facebook.com/profile.php?id=100089184953568';
  static const String email = 'mongfruits089@gmail.com';
  static const String address =
      'Số 098, đường Thủy Nguyên, khu đô thị Ecopark, '
      'Xuân Quan, Phụng Công, Hưng Yên';

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Liên hệ hỗ trợ',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header thân thiện
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.coffee, AppColors.coffeeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Mọng Fruits luôn sẵn sàng hỗ trợ bạn!\nCần giúp đỡ? Liên hệ ngay bên dưới.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (hotline.isNotEmpty)
            _item(
              icon: Icons.phone_rounded,
              color: AppColors.success,
              title: 'Hotline',
              value: hotline,
              onTap: () => _open('tel:$hotline'),
            ),
          if (zaloUrl.isNotEmpty)
            _item(
              icon: Icons.chat_rounded,
              color: const Color(0xFF0068FF),
              title: 'Zalo',
              value: 'Nhắn tin qua Zalo',
              onTap: () => _open(zaloUrl),
            ),
          if (facebookUrl.isNotEmpty)
            _item(
              icon: Icons.facebook_rounded,
              color: const Color(0xFF1877F2),
              title: 'Facebook',
              value: 'Fanpage Mọng Fruits',
              onTap: () => _open(facebookUrl),
            ),
          _item(
            icon: Icons.email_rounded,
            color: AppColors.hot,
            title: 'Email hỗ trợ',
            value: email,
            onTap: () => _open('mailto:$email'),
          ),
          _item(
            icon: Icons.location_on_rounded,
            color: AppColors.coffee,
            title: 'Địa chỉ quán',
            value: address,
            onTap: () => _open(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text('Cảm ơn bạn đã tin dùng Mọng Fruits 🍓',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                      const SizedBox(height: 3),
                      Text(value,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.35)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
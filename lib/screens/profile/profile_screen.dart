// ============================================================
//  FLUTTER
//  lib/screens/profile/profile_screen.dart
//  >> CHEP DE (nut Xoa tai khoan + xac nhan)
// ============================================================

// lib/screens/profile/profile_screen.dart
//
// Hồ sơ cá nhân: xem số điện thoại (định danh, không sửa) và sửa tên hiển thị.
//
// ⚠️ Lưu tên gọi PATCH /auth/me — endpoint này CHƯA xác nhận có trong backend.
// Nếu backend chưa hỗ trợ, nút Lưu sẽ báo lỗi rõ ràng (không làm hỏng gì khác).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repository_providers.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    // Nếu name null thì để trống (đừng đổ số điện thoại vào ô tên).
    _name = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _name.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên hiển thị không được để trống')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final updated =
          await ref.read(authRepositoryProvider).updateProfile(name: newName);
      ref.read(authProvider.notifier).updateUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã cập nhật hồ sơ'),
              backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      final msg = e.statusCode == 404
          ? 'Tính năng cập nhật tên cần backend hỗ trợ endpoint PATCH /auth/me'
          : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.delivery),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.coffee.withOpacity(0.12),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.coffee, size: 52),
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _label('Số điện thoại'),
          const SizedBox(height: 6),
          _readonlyField(
            icon: Icons.phone_rounded,
            value: user != null ? Formatters.prettyPhone(user.phone) : '—',
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Số điện thoại là định danh đăng nhập, không thể đổi.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          _label('Tên hiển thị'),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Nhập tên của bạn',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_forever_rounded,
                      color: AppColors.delivery),
              label: Text(_deleting ? 'Đang xoá…' : 'Xoá tài khoản',
                  style: const TextStyle(
                      color: AppColors.delivery,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tài khoản và thông tin cá nhân sẽ bị xoá vĩnh viễn. '
              'Lịch sử đơn hàng được giữ ẩn danh theo quy định kế toán.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Lưu thay đổi'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài khoản?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Bạn sẽ bị đăng xuất, '
          'thông tin cá nhân bị xoá và các voucher chưa dùng sẽ mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá tài khoản',
                style: TextStyle(color: AppColors.delivery)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản đã được xoá')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Xoá tài khoản thất bại, vui lòng thử lại'),
          backgroundColor: AppColors.delivery,
        ),
      );
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _readonlyField({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
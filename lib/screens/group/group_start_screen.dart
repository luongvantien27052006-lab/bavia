// lib/screens/group/group_start_screen.dart
//
// Bắt đầu đặt chung: tạo phòng mới hoặc nhập mã tham gia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/group_order_provider.dart';
import 'group_room_screen.dart';

class GroupStartScreen extends ConsumerStatefulWidget {
  final String? prefillCode;
  const GroupStartScreen({super.key, this.prefillCode});

  @override
  ConsumerState<GroupStartScreen> createState() => _GroupStartScreenState();
}

class _GroupStartScreenState extends ConsumerState<GroupStartScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillCode != null && widget.prefillCode!.isNotEmpty) {
      _codeCtrl.text = widget.prefillCode!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _err(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: AppColors.delivery),
    );
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final room = await ref
          .read(groupOrderRepositoryProvider)
          .createRoom(fulfillment: 'DELIVERY');
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => GroupRoomScreen(groupId: room.id)));
      }
    } catch (_) {
      _err('Không tạo được phòng, thử lại');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 4) {
      _err('Nhập mã phòng hợp lệ');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final room = await ref.read(groupOrderRepositoryProvider).join(code);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => GroupRoomScreen(groupId: room.id)));
      }
    } catch (_) {
      _err('Mã phòng không đúng hoặc phòng đã đóng');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Đặt chung'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Consumer(builder: (context, ref, _) {
            final active = ref.watch(activeGroupRoomProvider);
            return active.maybeWhen(
              data: (room) => room == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) =>
                                  GroupRoomScreen(groupId: room.id)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            Icon(Icons.meeting_room_rounded,
                                color: AppColors.success),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Bạn đang có phòng đang mở',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark)),
                                  Text('Mã ${room.code} · ${room.totalItems} món',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text('Vào lại',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            );
          }),
          const SizedBox(height: 8),
          Icon(Icons.groups_rounded, size: 64, color: AppColors.coffee),
          const SizedBox(height: 12),
          Text('Đặt nước cùng bạn bè',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
              'Tạo 1 phòng, chia mã cho mọi người cùng thêm món. '
              'Gộp thành 1 đơn, 1 lần giao, 1 phí ship.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo phòng mới'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coffee,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('hoặc', style: TextStyle(color: AppColors.textMuted)),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ]),
          const SizedBox(height: 24),
          Text('Nhập mã phòng',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'VD ABC123',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _join,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coffee,
                side: BorderSide(color: AppColors.coffee),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Tham gia phòng'),
          ),
        ],
      ),
    );
  }
}
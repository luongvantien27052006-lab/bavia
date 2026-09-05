// lib/screens/group/group_room_screen.dart
//
// Màn phòng đặt chung: mã phòng, món theo từng thành viên, chủ phòng chốt đơn.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/socket_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/group_order.dart';
import '../../models/order_model.dart';
import '../../providers/group_order_provider.dart';
import '../../repositories/group_order_repository.dart';
import '../../providers/address_provider.dart';
import '../../utils/formatters.dart';
import '../menu/menu_screen.dart';
import '../orders/order_detail_screen.dart';
import 'group_bill_screen.dart';

class GroupRoomScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupRoomScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends ConsumerState<GroupRoomScreen> {
  Timer? _poll;
  bool _busy = false;
  String? _voucherCode;
  VoidCallback? _unsub;

  @override
  void initState() {
    super.initState();
    // Realtime: tham gia kênh phòng + lắng nghe cập nhật -> tải lại ngay.
    SocketService.instance.emit('group.subscribe', {'groupId': widget.groupId});
    _unsub = SocketService.instance.on('group.updated', (data) {
      final gid = data is Map ? data['groupId'] : null;
      if (mounted && (gid == null || gid == widget.groupId)) {
        ref.invalidate(groupRoomProvider(widget.groupId));
      }
    });
    // Đơn đổi trạng thái (cho cả nhóm theo dõi sau khi chốt).
    SocketService.instance.on('order.statusChanged', (_) {
      if (mounted) ref.invalidate(groupRoomProvider(widget.groupId));
    });
    // Fallback polling thưa (phòng khi socket rớt).
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) ref.invalidate(groupRoomProvider(widget.groupId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _unsub?.call();
    SocketService.instance
        .emit('group.unsubscribe', {'groupId': widget.groupId});
    super.dispose();
  }

  GroupOrderRepository get _repo => ref.read(groupOrderRepositoryProvider);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_msg(e)), backgroundColor: AppColors.delivery),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(groupRoomProvider(widget.groupId));
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.length > 120 ? 'Có lỗi xảy ra, thử lại' : s.replaceAll('Exception: ', '');
  }

  void _addItems() {
    ref.read(activeGroupProvider.notifier).state = widget.groupId;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(groupRoomProvider(widget.groupId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Đặt chung'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được phòng. Có thể phòng đã đóng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
        data: (room) => _body(room),
      ),
    );
  }

  Widget _body(GroupOrder room) {
    if (room.isOrdered) return _orderedView(room);
    if (room.isCollecting) return _collectingView(room);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _codeCard(room),
              const SizedBox(height: 12),
              _guidanceBanner(room),
              if (room.isHost) _settingsCard(room),
              const SizedBox(height: 4),
              if (room.participants.isEmpty)
                _emptyHint()
              else
                ...room.participants.map((p) => _participantCard(room, p)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _bottomBar(room),
      ],
    );
  }

  Widget _guidanceBanner(GroupOrder room) {
    String msg;
    IconData icon;
    Color color;
    if (room.isOpen) {
      icon = Icons.add_shopping_cart_rounded;
      color = AppColors.coffee;
      msg = room.isHost
          ? 'Đang gom món — thêm món, rồi bấm "Khoá phòng" khi mọi người xong.'
          : 'Thêm món của bạn vào phòng. Chủ phòng sẽ chốt đơn giúp cả nhóm.';
    } else {
      icon = Icons.lock_rounded;
      color = AppColors.hot;
      if (room.isHost) {
        msg = room.isSplit
            ? 'Đã khoá — bấm "Thu tiền từng người" để tạo QR cho mọi người trả.'
            : 'Đã khoá — bấm "Chốt & thanh toán" để đặt đơn cho cả nhóm.';
      } else {
        msg = room.isSplit
            ? 'Đã khoá — chờ chủ phòng bật thu tiền, bạn sẽ nhận QR phần của mình.'
            : 'Đã khoá — chờ chủ phòng thanh toán & đặt đơn.';
      }
    }
    return Container(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _codeCard(GroupOrder room) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.coffee, AppColors.coffeeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Mã phòng — chia sẻ để bạn bè vào cùng',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(room.code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6)),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã phòng')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              room.isLocked ? '🔒 Đã khoá' : '🟢 Đang mở · thêm món được',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareInvite(room),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Chia sẻ link'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQr(room),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Mã QR'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _inviteLink(GroupOrder room) =>
      '${ApiConfig.inviteBaseUrl}/join.html?code=${room.code}';

  void _shareInvite(GroupOrder room) {
    final link = _inviteLink(room);
    final msg = 'Cùng đặt nước ở Mọng Fruits nhé! 🍓\n'
        'Vào phòng đặt chung (mã ${room.code}):\n$link';
    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đã sao chép lời mời — dán vào Zalo/Messenger để gửi bạn bè'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showQr(GroupOrder room) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quét để tham gia',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Mã phòng: ${room.code}',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=440x440&data=${Uri.encodeComponent(_inviteLink(room))}',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text('Mã phòng: ${room.code}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffee,
                      foregroundColor: Colors.white),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint() => Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('Chưa có món nào. Bấm "Thêm món" để bắt đầu 🍹',
            style: TextStyle(color: AppColors.textMuted)),
      );

  Widget _participantCard(GroupOrder room, GroupParticipant p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.coffee.withOpacity(0.15),
                child: Text(
                    (p.name.isNotEmpty ? p.name[0] : '?').toUpperCase(),
                    style: TextStyle(
                        color: AppColors.coffee,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(p.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textDark)),
              if (p.isHost) _tag('Chủ phòng', AppColors.coffee),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.money(p.subtotal),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                  if (p.remaining != null)
                    Text('còn ${Formatters.money(p.remaining!)}',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...p.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${it.quantity}×',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.coffee)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName,
                              style: TextStyle(color: AppColors.textDark)),
                          if (it.note != null && it.note!.isNotEmpty)
                            Text(it.note!,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(Formatters.money(it.lineTotal),
                        style: TextStyle(color: AppColors.textDark)),
                    if (room.isOpen && it.isMine)
                      GestureDetector(
                        onTap: () =>
                            _run(() => _repo.removeItem(room.id, it.id).then((_) {})),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.delivery),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _settingsCard(GroupOrder room) {
    final limit = room.spendingLimit;
    final hostPays = room.paymentMode == 'HOST_PAYS';
    return GestureDetector(
      onTap: (room.isOpen || room.isLocked) ? () => _openSettings(room) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.coffee, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cài đặt phòng',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                      '${hostPays ? 'Chủ trả hết' : 'Chia tiền'} · '
                      '${limit != null ? 'Hạn mức ${Formatters.money(limit)}' : 'Không giới hạn'} · '
                      '${room.splitMethod == 'EQUAL' ? 'Ship chia đều' : 'Ship theo món'}',
                      style:
                          TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _sheetChoice(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.coffee : AppColors.textMuted,
                size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: AppColors.textDark)),
          ]),
        ),
      );

  Future<void> _openSettings(GroupOrder room) async {
    final limitCtrl = TextEditingController(
        text: room.spendingLimit != null ? room.spendingLimit.toString() : '');
    String payMode = room.paymentMode;
    String splitMethod = room.splitMethod;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              20 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cài đặt phòng',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 16),
              Text('Hạn mức mỗi người (đ)',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Bỏ trống = không giới hạn',
                  filled: true,
                  fillColor: AppColors.cream,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thanh toán',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              _sheetChoice('Chủ phòng trả hết', payMode == 'HOST_PAYS',
                  () => setSheet(() => payMode = 'HOST_PAYS')),
              _sheetChoice('Mỗi người tự trả', payMode == 'SPLIT',
                  () => setSheet(() => payMode = 'SPLIT')),
              const SizedBox(height: 12),
              Text('Chia phí ship',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              _sheetChoice('Theo giá trị món', splitMethod == 'PROPORTIONAL',
                  () => setSheet(() => splitMethod = 'PROPORTIONAL')),
              _sheetChoice('Chia đều', splitMethod == 'EQUAL',
                  () => setSheet(() => splitMethod = 'EQUAL')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final limit = int.tryParse(limitCtrl.text.trim()) ?? 0;
                    await _run(() => ref
                        .read(groupOrderRepositoryProvider)
                        .updateSettings(room.id,
                            spendingLimit: limit,
                            paymentMode: payMode,
                            splitMethod: splitMethod)
                        .then((_) {}));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffee,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Lưu cài đặt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(GroupOrder room) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Tổng (${room.totalItems} món)',
                  style: TextStyle(color: AppColors.textMuted)),
              const Spacer(),
              Text(Formatters.money(room.subtotal),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Chưa gồm phí ship · tính khi chốt đơn',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (room.isOpen)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _addItems,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm món'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coffee,
                        side: BorderSide(color: AppColors.coffee),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                if (room.isHost) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_busy || room.totalItems == 0)
                          ? null
                          : () => _run(() => _repo.setLocked(room.id, true).then((_) {})),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coffee,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Khoá phòng'),
                    ),
                  ),
                ],
              ],
            ),
          if (room.isLocked && room.isHost)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => _repo.setLocked(room.id, false).then((_) {})),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Mở lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => room.isSplit
                            ? _startCollection(room)
                            : _openCheckout(room),
                    icon: Icon(room.isSplit
                        ? Icons.request_quote_rounded
                        : Icons.check_circle_rounded),
                    label: Text(
                        room.isSplit ? 'Thu tiền từng người' : 'Chốt & thanh toán'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          if (room.isLocked && !room.isHost)
            Text('Phòng đã khoá — chờ chủ phòng chốt đơn',
                style: TextStyle(color: AppColors.textMuted)),
          if (room.isHost && (room.isOpen || room.isLocked)) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : () => _confirmCancel(room),
              child: Text('Huỷ phòng',
                  style: TextStyle(color: AppColors.delivery, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(GroupOrder room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ phòng?'),
        content: const Text('Tất cả món trong phòng sẽ bị xoá.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Huỷ phòng')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.cancel(room.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openCheckout(GroupOrder room) async {
    PaymentMethodType method = PaymentMethodType.cod;
    final voucherCtrl = TextEditingController(text: _voucherCode ?? '');
    final addresses = await ref.read(addressesProvider.future).catchError(
          (_) => <dynamic>[],
        );
    dynamic addr;
    if (room.isDelivery && addresses is List && addresses.isNotEmpty) {
      addr = addresses.firstWhere(
        (a) => a.isDefault == true,
        orElse: () => addresses.first,
      );
    }

    if (!mounted) return;
    if (room.isDelivery && addr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Bạn cần thêm địa chỉ giao hàng trước'),
            backgroundColor: AppColors.delivery),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chốt đơn nhóm',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Bạn (chủ phòng) sẽ thanh toán cho cả nhóm.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              if (room.isDelivery && addr != null) ...[
                const SizedBox(height: 12),
                Text('Giao đến: ${addr.detailedAddress}',
                    style: TextStyle(fontSize: 13, color: AppColors.textDark)),
              ],
              const SizedBox(height: 16),
              Text('Mã giảm giá (tuỳ chọn)',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: voucherCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Nhập mã giảm giá / freeship',
                  filled: true,
                  fillColor: AppColors.cream,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thanh toán',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              RadioListTile<PaymentMethodType>(
                value: PaymentMethodType.cod,
                groupValue: method,
                onChanged: (v) => setSheet(() => method = v!),
                title: const Text('Tiền mặt khi nhận'),
                activeColor: AppColors.coffee,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<PaymentMethodType>(
                value: PaymentMethodType.bankQr,
                groupValue: method,
                onChanged: (v) => setSheet(() => method = v!),
                title: const Text('Chuyển khoản QR'),
                activeColor: AppColors.coffee,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _voucherCode = voucherCtrl.text.trim().isEmpty
                        ? null
                        : voucherCtrl.text.trim().toUpperCase();
                    await _doCheckout(room, method, addr);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text('Xác nhận đặt đơn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doCheckout(
      GroupOrder room, PaymentMethodType method, dynamic addr) async {
    await _run(() async {
      final result = await _repo.checkout(
        room.id,
        paymentMethod: method,
        deliveryAddress:
            room.isDelivery && addr != null ? addr.toDeliveryJson() : null,
        voucherCode: _voucherCode,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: result.order.id),
          ),
        );
      }
    });
  }

  Widget _orderTracker(String? status) {
    const steps = ['Xác nhận', 'Đang pha', 'Sẵn sàng', 'Đang giao', 'Đã nhận'];
    int stage = 1;
    switch ((status ?? '').toUpperCase()) {
      case 'CONFIRMED':
        stage = 1;
        break;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        stage = 2;
        break;
      case 'READY':
        stage = 3;
        break;
      case 'DELIVERING':
        stage = 4;
        break;
      case 'DELIVERED':
        stage = 5;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < stage;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      done ? Icons.check_rounded : Icons.circle,
                      size: done ? 15 : 8,
                      color: done ? Colors.white : AppColors.textMuted),
                ),
                const SizedBox(height: 5),
                Text(steps[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                        color: done ? AppColors.textDark : AppColors.textMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _startCollection(GroupOrder room) async {
    final voucherCtrl = TextEditingController();
    final addresses = await ref
        .read(addressesProvider.future)
        .catchError((_) => <dynamic>[]);
    dynamic addr;
    if (room.isDelivery && addresses is List && addresses.isNotEmpty) {
      addr = addresses.firstWhere((a) => a.isDefault == true,
          orElse: () => addresses.first);
    }
    if (!mounted) return;
    if (room.isDelivery && addr == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Cần thêm địa chỉ giao hàng trước'),
          backgroundColor: AppColors.delivery));
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thu tiền từng người',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(
                'Mỗi thành viên nhận mã QR trả phần của mình. Bạn xác nhận đã thu đủ rồi gửi đơn.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            if (room.isDelivery && addr != null) ...[
              const SizedBox(height: 12),
              Text('Giao đến: ${addr.detailedAddress}',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
            const SizedBox(height: 14),
            Text('Mã giảm giá (tuỳ chọn)',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: voucherCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nhập mã (nếu có)',
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _run(() => _repo
                      .startCollection(room.id,
                          deliveryAddress: room.isDelivery && addr != null
                              ? addr.toDeliveryJson()
                              : null,
                          voucherCode: voucherCtrl.text.trim().isEmpty
                              ? null
                              : voucherCtrl.text.trim().toUpperCase())
                      .then((_) {}));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Tạo QR thu tiền'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectingView(GroupOrder room) {
    final myPay = room.myPayment;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.coffee.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.coffee.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.request_quote_rounded, color: AppColors.coffee),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Đang thu tiền — mỗi người trả phần của mình.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textDark)),
                  ),
                ]),
              ),
              if (myPay != null) ...[
                const SizedBox(height: 16),
                _myPaymentCard(room, myPay),
              ],
              const SizedBox(height: 16),
              Text('Tình trạng thanh toán',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              ...room.participants.map((p) => _paymentStatusRow(p)),
            ],
          ),
        ),
        if (room.isHost) _finalizeBar(room),
      ],
    );
  }

  Widget _myPaymentCard(GroupOrder room, GroupPayment pay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coffee, width: 1.5),
      ),
      child: Column(
        children: [
          Text('Phần của bạn',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(Formatters.money(pay.amount),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.coffee)),
          const SizedBox(height: 12),
          if (pay.qrUrl != null && pay.isPending)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(pay.qrUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 60, child: Center(child: Text('Không tải được QR')))),
            ),
          if (pay.transferContent != null && pay.isPending) ...[
            const SizedBox(height: 8),
            Text('Nội dung CK: ${pay.transferContent}',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 14),
          if (pay.isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _busy ? null : () => _run(() => _repo.submitPayment(room.id).then((_) {})),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Tôi đã chuyển khoản'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coffee,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                  color: (pay.status == 'CONFIRMED'
                          ? AppColors.success
                          : AppColors.hot)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(
                  pay.status == 'CONFIRMED'
                      ? '✓ Đã nhận tiền của bạn'
                      : 'Đang chờ hệ thống đối soát...',
                  style: TextStyle(
                      color: pay.status == 'CONFIRMED'
                          ? AppColors.success
                          : AppColors.hot,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _paymentStatusRow(GroupParticipant p) {
    Color c;
    String label;
    switch (p.paymentStatus) {
      case 'CONFIRMED':
        c = AppColors.success;
        label = '✓ Đã nhận tiền';
        break;
      case 'SUBMITTED':
        c = AppColors.hot;
        label = 'Chờ đối soát';
        break;
      default:
        c = AppColors.textMuted;
        label = 'Chưa trả';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: Text('${p.name}${p.isHost ? ' (chủ phòng)' : ''}',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ),
        if (p.paymentAmount != null) ...[
          Text(Formatters.money(p.paymentAmount!),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 10),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999)),
          child: Text(label,
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _finalizeBar(GroupOrder room) {
    final confirmed =
        room.participants.where((p) => p.paymentStatus == 'CONFIRMED').length;
    final total = room.participants.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                    'Đã nhận $confirmed/$total. Hệ thống TỰ đối soát — đủ tiền là đơn tự gửi đi.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _confirmCancelCollection(room),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Huỷ thu tiền'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.delivery,
                side: BorderSide(color: AppColors.delivery.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelCollection(GroupOrder room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ thu tiền?'),
        content: const Text(
            'Đơn chờ sẽ bị huỷ và phòng mở lại để chỉnh. Người đã chuyển khoản cần được hoàn tiền thủ công.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Huỷ thu tiền')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _repo.cancelCollection(room.id).then((_) {}));
    }
  }

  Widget _orderedView(GroupOrder room) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đã chốt đơn nhóm 🎉',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text('${room.totalItems} món · ${Formatters.money(room.subtotal)}',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            _orderTracker(room.orderStatus),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GroupBillScreen(groupId: room.id))),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Xem bảng kê chia tiền'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coffee,
                  side: BorderSide(color: AppColors.coffee),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
            const SizedBox(height: 10),
            if (room.orderId != null)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderDetailScreen(orderId: room.orderId!),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coffee,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14)),
                child: const Text('Xem đơn hàng'),
              ),
          ],
        ),
      ),
    );
  }
}
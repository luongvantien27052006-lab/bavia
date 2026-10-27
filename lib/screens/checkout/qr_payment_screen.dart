// lib/screens/checkout/qr_payment_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Màn thanh toán chuyển khoản QR: VietQR + nội
// dung CK + đếm ngược. Lắng nghe socket "payment.confirmed" để tự nhảy sang
// màn thành công; có nút kiểm tra thủ công + hỏi định kỳ làm dự phòng.
// Thêm: lưu ảnh QR vào máy, mở thẳng app ngân hàng (VietQR deeplink) và huỷ
// thanh toán.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show ImageByteFormat;
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../core/realtime/socket_service.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/repository_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/stage.dart';
import 'order_success_screen.dart';

class QrPaymentScreen extends ConsumerStatefulWidget {
  final PlaceOrderResult result;
  const QrPaymentScreen({super.key, required this.result});

  @override
  ConsumerState<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends ConsumerState<QrPaymentScreen> {
  VoidCallback? _disposeListener;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  Duration _remaining = Duration.zero;
  bool _checking = false;
  bool _navigated = false;
  bool _saving = false;
  bool _cancelling = false;
  bool _qrLoaded = false;

  /// Khung chứa ảnh QR — chụp lại để lưu vào thư viện ảnh.
  final GlobalKey _qrKey = GlobalKey();

  PaymentInfo get _payment => widget.result.payment!;
  String get _orderId => widget.result.order.id;

  @override
  void initState() {
    super.initState();
    _setupCountdown();
    _listenSocket();
    _startPolling();
    _BankLogos.load(); // tải sẵn logo app ngân hàng cho bảng chọn
  }

  void _setupCountdown() {
    final expires = _payment.expiresAt;
    if (expires == null) {
      _remaining = const Duration(minutes: 10);
    } else {
      _remaining = expires.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    }
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  void _listenSocket() {
    _disposeListener =
        SocketService.instance.on('payment.confirmed', (data) {
      // data: { orderId, finalAmount }
      final id = (data is Map) ? data['orderId']?.toString() : null;
      if (id == null || id == _orderId) {
        _onPaymentConfirmed();
      }
    });
  }

  /// Dự phòng: nếu socket lỡ rớt, cứ ~6s hỏi trạng thái đơn 1 lần.
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_navigated || !mounted) return;
      await _checkOrderStatus(silent: true);
    });
  }

  Future<void> _checkOrderStatus({bool silent = false}) async {
    if (_navigated) return;
    if (!silent) setState(() => _checking = true);
    try {
      final order =
          await ref.read(orderRepositoryProvider).fetchOrderById(_orderId);
      if (order.paymentStatus == PaymentStatus.confirmed) {
        _onPaymentConfirmed(order: order);
      } else if (!silent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Chưa nhận được thanh toán. Vui lòng đợi.')),
          );
        }
      }
    } catch (_) {
      // im lặng khi poll nền
    } finally {
      if (!silent && mounted) setState(() => _checking = false);
    }
  }

  void _onPaymentConfirmed({OrderModel? order}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          order: order ?? widget.result.order,
          paid: true,
        ),
      ),
    );
  }

  // ─────────────────────── Lưu ảnh QR ───────────────────────

  Future<void> _saveQr() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await _writeQrToGallery();
      if (ok) {
        HapticFeedback.mediumImpact();
        _toast('Đã lưu mã QR vào thư viện ảnh. Mở app ngân hàng → Quét QR → '
            'chọn ảnh từ thư viện để thanh toán.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Chụp khung QR rồi lưu vào thư viện ảnh. Trả về true nếu lưu được.
  /// [quiet] = không báo lỗi (dùng khi tự lưu trước lúc mở app ngân hàng).
  Future<bool> _writeQrToGallery({bool quiet = false}) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess && !await Gal.requestAccess()) {
        if (!quiet) {
          _toast('Hãy cho phép Mọng Fruits lưu ảnh vào thư viện trong Cài đặt.');
        }
        return false;
      }
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('QR chưa sẵn sàng');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw Exception('Không tạo được ảnh');
      await Gal.putImageBytes(
        data.buffer.asUint8List(),
        name: 'MongFruits_QR_${_payment.transferContent}',
      );
      return true;
    } on GalException catch (e) {
      if (!quiet) {
        _toast(e.type == GalExceptionType.accessDenied
            ? 'Hãy cho phép Mọng Fruits lưu ảnh vào thư viện trong Cài đặt.'
            : 'Không lưu được ảnh, vui lòng thử lại.');
      }
      return false;
    } catch (_) {
      if (!quiet) _toast('Không lưu được ảnh, vui lòng thử lại.');
      return false;
    }
  }

  // ─────────────────────── Mở app ngân hàng ───────────────────────

  /// Mã ngân hàng NHẬN tiền (theo VietQR) — lấy từ BIN backend trả về,
  /// hoặc bóc từ URL ảnh QR (…/image/<bin>-<stk>-<template>.png).
  String? get _receiverBankCode {
    var bin = _payment.bankBin;
    if (bin == null || bin.isEmpty) {
      final m = RegExp(r'/image/(\d{6})-').firstMatch(_payment.qrImageUrl);
      bin = m?.group(1);
    }
    if (bin == null) return null;
    return _binToCode[bin] ?? bin;
  }

  String? get _accountNo {
    final no = _payment.bankAccountNo;
    if (no != null && no.isNotEmpty) return no;
    final m =
        RegExp(r'/image/\d{6}-([0-9A-Za-z]+)-').firstMatch(_payment.qrImageUrl);
    return m?.group(1);
  }

  bool get _canOpenBank => _receiverBankCode != null && _accountNo != null;

  Future<void> _openBankApp(_BankApp app) async {
    Navigator.of(context).pop(); // đóng bảng chọn
    // App ngân hàng KHÔNG tự điền được -> lưu sẵn ảnh QR để khách chọn
    // "Quét QR → Ảnh": cách này app nào cũng điền đủ STK, tên, tiền, nội dung.
    var savedQr = false;
    if (!app.autofill && _qrLoaded) {
      savedQr = await _writeQrToGallery(quiet: true);
    }
    // Dự phòng cuối: nội dung CK đã nằm sẵn trong bộ nhớ tạm để dán.
    await Clipboard.setData(ClipboardData(text: _payment.transferContent));
    final uri = Uri.https('dl.vietqr.io', '/pay', {
      'app': app.id,
      'ba': '${_accountNo!}@${_receiverBankCode!}',
      'am': _payment.amount.toString(),
      'tn': _payment.transferContent,
      if (_payment.bankAccountName != null) 'bn': _payment.bankAccountName!,
      'url': 'mongfruits://payment',
    });
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      _toast('Không mở được ${app.name}. Bạn có thể lưu mã QR rồi quét trong app.');
    } else if (app.autofill) {
      _toast('${app.name} sẽ mở màn chuyển khoản với thông tin điền sẵn. '
          'Kiểm tra lại rồi bấm Chuyển nhé.');
    } else if (savedQr) {
      _toast('Đã lưu mã QR vào thư viện. Trong ${app.name}: chọn Quét QR → '
          'Ảnh → chọn ảnh vừa lưu để điền đủ thông tin.');
    } else {
      _toast('Đã sao chép nội dung CK. Quay lại đây sau khi chuyển khoản nhé.');
    }
  }

  void _showBankSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: St.base,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: St.line(0.3),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Chọn app ngân hàng',
                    style: TextStyle(
                        color: St.fg(),
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _sheetSection(
                      'Tự điền sẵn thông tin',
                      'Mở thẳng màn chuyển khoản: số tài khoản, tên, số tiền '
                          'và nội dung đã điền đủ.',
                      _bankApps.where((b) => b.autofill).toList(),
                    ),
                    const SizedBox(height: 14),
                    _sheetSection(
                      'Ngân hàng khác',
                      'Mã QR sẽ được lưu vào thư viện ảnh. Trong app ngân hàng '
                          'chọn Quét QR → Ảnh → chọn ảnh vừa lưu.',
                      _bankApps.where((b) => !b.autofill).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetSection(String title, String hint, List<_BankApp> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(title,
              style: TextStyle(
                  color: St.fg(),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Text(hint,
              style: TextStyle(color: St.fg(0.6), fontSize: 12.5)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: apps.length,
          itemBuilder: (_, i) => _bankTile(apps[i]),
        ),
      ],
    );
  }

  Widget _bankTile(_BankApp b) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openBankApp(b),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _BankLogo(b),
              if (b.autofill)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E9E5B),
                      shape: BoxShape.circle,
                      border: Border.all(color: St.base, width: 2),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            b.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: St.fg(0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Huỷ thanh toán ───────────────────────

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ thanh toán?'),
        content: const Text(
            'Đơn hàng sẽ bị huỷ và hoàn lại voucher/điểm (nếu có).\n\n'
            'Nếu bạn ĐÃ chuyển khoản, đừng huỷ — hãy bấm "Tôi đã chuyển khoản" '
            'để hệ thống kiểm tra.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục thanh toán')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ đơn',
                style: TextStyle(color: Color(0xFFD64545))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    final repo = ref.read(orderRepositoryProvider);
    try {
      // Tiền vừa về đúng lúc bấm huỷ -> coi như đã thanh toán, không huỷ.
      final latest = await repo.fetchOrderById(_orderId);
      if (latest.paymentStatus == PaymentStatus.confirmed) {
        _onPaymentConfirmed(order: latest);
        return;
      }
      await repo.cancelOrder(_orderId);
      _navigated = true;
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
          const SnackBar(content: Text('Đã huỷ đơn hàng')));
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Không huỷ được đơn, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(msg), duration: const Duration(seconds: 4)));
  }

  @override
  void dispose() {
    _disposeListener?.call();
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    const tint = Color(0xFF2FB4C9); // xanh ngân hàng — dễ phân biệt màn trả tiền
    // Vòng đếm ngược: thang 10 phút (mã QR thường hết hạn sau 10 phút).
    final frac = (_remaining.inSeconds / 600).clamp(0.0, 1.0);

    return StageScaffold(
      title: 'Thanh toán QR',
      subtitle: expired ? 'Mã QR đã hết hạn' : 'Tự động xác nhận khi nhận tiền',
      tint: tint,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          // Khung QR trắng (để app ngân hàng quét chuẩn) nổi trên nền tối.
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kOnColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: tint.withValues(alpha: 0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 14)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                    color: kOnColor,
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _payment.qrImageUrl,
                      width: 236,
                      height: 236,
                      fit: BoxFit.contain,
                      imageBuilder: (_, provider) {
                        if (!_qrLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _qrLoaded = true);
                          });
                        }
                        return Image(
                            image: provider,
                            width: 236,
                            height: 236,
                            fit: BoxFit.contain);
                      },
                      placeholder: (_, __) => const SizedBox(
                          width: 236,
                          height: 236,
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4))),
                      errorWidget: (_, __, ___) => const SizedBox(
                        width: 236,
                        height: 236,
                        child: Icon(Icons.broken_image_rounded,
                            size: 64, color: Colors.black38),
                      ),
                    ),
                  ),
                  ),
                  ),
                  if (expired)
                    Container(
                      width: 236,
                      height: 236,
                      decoration: BoxDecoration(
                        color: kOnColor.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Mã đã hết hạn',
                            style: TextStyle(
                                color: kInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Đếm ngược dạng viên + thanh tiến độ.
          if (!expired)
            Center(
              child: StageGlass(
                radius: 999,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: frac,
                        strokeWidth: 2.4,
                        color: St.fg(),
                        backgroundColor: St.line(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Còn $_countdownText',
                        style:  TextStyle(
                            color: St.fg(),
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Quét bằng app ngân hàng, MoMo hoặc ZaloPay',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: St.fg(0.7)),
            ),
          ),
          const SizedBox(height: 14),
          _quickActions(expired),
          const SizedBox(height: 16),
          _amountCard(tint),
          const SizedBox(height: 10),
          _infoCard(),
          const SizedBox(height: 10),
          Text(
            'Giữ nguyên nội dung chuyển khoản để đơn được xác nhận tự động.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: St.fg(0.55)),
          ),
          const SizedBox(height: 22),
          StageButton(
            label: 'Tôi đã chuyển khoản',
            icon: Icons.refresh_rounded,
            white: true,
            loading: _checking,
            onTap: _checking ? null : () => _checkOrderStatus(),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: (_cancelling || _checking) ? null : _confirmCancel,
              icon: _cancelling
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: St.fg(0.7)))
                  : Icon(Icons.close_rounded, size: 18, color: St.fg(0.7)),
              label: Text('Huỷ thanh toán',
                  style: TextStyle(
                      color: St.fg(0.7), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Hai nút nhanh: lưu ảnh QR + mở app ngân hàng.
  Widget _quickActions(bool expired) {
    return Row(
      children: [
        Expanded(
          child: _actionPill(
            icon: Icons.download_rounded,
            label: 'Lưu mã QR',
            loading: _saving,
            onTap: (expired || !_qrLoaded || _saving) ? null : _saveQr,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionPill(
            icon: Icons.account_balance_rounded,
            label: 'Mở app ngân hàng',
            onTap: (expired || !_canOpenBank) ? null : _showBankSheet,
          ),
        ),
      ],
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.45,
      child: StageGlass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: St.fg()))
            else
              Icon(icon, size: 19, color: St.fg()),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: St.fg(),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountCard(Color tint) {
    return StageGlass(
      highlight: tint,
      radius: 20,
      child: Row(
        children: [
           Text('Số tiền',
              style: TextStyle(
                  color: St.fg(), fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(Formatters.money(_payment.amount),
              style:  TextStyle(
                  color: St.fg(),
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          _copyBtn(_payment.amount.toString(), 'Sao chép số tiền'),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return StageGlass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (_payment.bankAccountName != null)
            _infoRow('Chủ tài khoản', _payment.bankAccountName!),
          if (_payment.bankAccountNo != null)
            _infoRow('Số tài khoản', _payment.bankAccountNo!, copy: true),
          _infoRow('Nội dung CK', _payment.transferContent, copy: true),
        ],
      ),
    );
  }

  Widget _copyBtn(String value, String label) {
    return IconButton(
      tooltip: label,
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã sao chép'), duration: Duration(seconds: 1)),
        );
      },
      icon: Icon(Icons.copy_rounded,
          size: 18, color: St.fg(0.85)),
    );
  }

  Widget _infoRow(String label, String value, {bool copy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style: TextStyle(color: St.fg(0.6))),
          ),
          Expanded(
            child: Text(value,
                style:  TextStyle(
                    color: St.fg(), fontWeight: FontWeight.w700)),
          ),
          if (copy) _copyBtn(value, 'Sao chép $label') else const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ─────────────────────── Danh sách app ngân hàng ───────────────────────

class _BankApp {
  final String id; // appId của VietQR deeplink (dl.vietqr.io/pay?app=…)
  final String name;
  final String short;
  final Color color;

  /// App ngân hàng hỗ trợ tự điền khi mở deeplink (theo changelog VietQR).
  /// App khác chỉ mở app -> dùng ảnh QR đã lưu để điền đủ thông tin.
  final bool autofill;
  const _BankApp(this.id, this.name, this.short, this.color,
      {this.autofill = false});
}

/// Xếp theo độ phổ biến. appId theo api.vietqr.io/v2/{android,ios}-app-deeplinks.
/// Tự điền (2026): MB, VietinBank, BIDV, ACB, OCB — thêm khi VietQR mở rộng.
const _bankApps = <_BankApp>[
  _BankApp('mb', 'MB Bank', 'MB', Color(0xFF1E3A8A),
      autofill: true),
  _BankApp('vcb', 'Vietcombank', 'VCB', Color(0xFF0B7A3E)),
  _BankApp('tcb', 'Techcombank', 'TCB', Color(0xFFE31837)),
  _BankApp('icb', 'VietinBank', 'CTG', Color(0xFF0B5CAB),
      autofill: true),
  _BankApp('bidv', 'BIDV', 'BIDV', Color(0xFF1C6B6B),
      autofill: true),
  _BankApp('vba', 'Agribank', 'AGR', Color(0xFFA6192E)),
  _BankApp('vpb', 'VPBank NEO', 'VPB', Color(0xFF00965E)),
  _BankApp('acb', 'ACB ONE', 'ACB', Color(0xFF1F4FA0),
      autofill: true),
  _BankApp('tpb', 'TPBank', 'TPB', Color(0xFF5B2C83)),
  _BankApp('cake', 'Cake', 'CAKE', Color(0xFFEC4899)),
  _BankApp('ocb', 'OCB OMNI', 'OCB', Color(0xFF178A4C),
      autofill: true),
  _BankApp('timo', 'Timo', 'TIMO', Color(0xFF2B2B6E)),
  _BankApp('lpb', 'LPBank', 'LPB', Color(0xFFF26522)),
  _BankApp('hdb', 'HDBank', 'HDB', Color(0xFFE2231A)),
  _BankApp('vib', 'MyVIB', 'VIB', Color(0xFF1C4AA0)),
  _BankApp('shb', 'SHB SAHA', 'SHB', Color(0xFFF58220)),
  _BankApp('seab', 'SeABank', 'SEA', Color(0xFFD71920)),
  _BankApp('eib', 'Eximbank', 'EIB', Color(0xFF0A4C9A)),
  _BankApp('scb', 'SCB', 'SCB', Color(0xFF0071BC)),
  _BankApp('nab', 'Nam A Bank', 'NAB', Color(0xFF00589F)),
];

/// BIN napas -> mã ngân hàng VietQR (dùng cho tham số ba=<stk>@<mã>).
const _binToCode = <String, String>{
  '970422': 'mb',
  '970436': 'vcb',
  '970407': 'tcb',
  '970415': 'icb',
  '970418': 'bidv',
  '970405': 'vba',
  '970432': 'vpb',
  '970416': 'acb',
  '970423': 'tpb',
  '970403': 'stb',
  '970441': 'vib',
  '970426': 'msb',
  '970443': 'shb',
  '970437': 'hdb',
  '970448': 'ocb',
  '970429': 'scb',
  '970431': 'eib',
  '970449': 'lpb',
  '970440': 'seab',
  '970428': 'nab',
  '970454': 'vccb',
  '546034': 'cake',
  '963388': 'timo',
};

// ─────────────────────── Logo app ngân hàng ───────────────────────

/// Logo THẬT của app ngân hàng, lấy từ API danh sách deeplink của VietQR
/// (api.vietqr.io/v2/{android,ios}-app-deeplinks -> appLogo). Tải 1 lần mỗi
/// phiên, ảnh được cache. Chưa tải được -> hiện ô chữ viết tắt như cũ.
class _BankLogos {
  static final ValueNotifier<Map<String, String>> logos =
      ValueNotifier(const {});
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _fetch();

  static Future<Map<String, String>> _list(Dio dio, String platform) async {
    final m = <String, String>{};
    try {
      final res =
          await dio.get('https://api.vietqr.io/v2/$platform-app-deeplinks');
      final data = res.data is String ? jsonDecode(res.data as String) : res.data;
      final apps = data is Map ? data['apps'] : null;
      if (apps is List) {
        for (final a in apps) {
          if (a is! Map) continue;
          final id = a['appId']?.toString();
          final logo = a['appLogo']?.toString();
          if (id != null && logo != null && logo.startsWith('http')) {
            m[id] = logo;
          }
        }
      }
    } catch (_) {}
    return m;
  }

  static Future<void> _fetch() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ));
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final lists = await Future.wait([_list(dio, 'android'), _list(dio, 'ios')]);
    // Ưu tiên danh sách đúng nền tảng, thiếu thì lấy bên còn lại.
    final merged = ios
        ? {...lists[0], ...lists[1]}
        : {...lists[1], ...lists[0]};
    if (merged.isEmpty) {
      _loading = null; // lỗi mạng -> lần mở sau thử lại
      return;
    }
    logos.value = merged;
  }
}

class _BankLogo extends StatelessWidget {
  final _BankApp bank;
  const _BankLogo(this.bank);

  Widget _fallback() => Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bank.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          bank.short,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, String>>(
      valueListenable: _BankLogos.logos,
      builder: (context, logos, _) {
        final url = logos[bank.id];
        if (url == null) return _fallback();
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: St.line(0.12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: url,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => _fallback(),
            errorWidget: (_, __, ___) => _fallback(),
          ),
        );
      },
    );
  }
}

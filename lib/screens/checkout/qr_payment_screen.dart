// lib/screens/checkout/qr_payment_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Màn thanh toán chuyển khoản QR: VietQR + nội
// dung CK + đếm ngược. Lắng nghe socket "payment.confirmed" để tự nhảy sang
// màn thành công; có nút kiểm tra thủ công + hỏi định kỳ làm dự phòng.

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/socket_service.dart';
import '../../models/order_model.dart';
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

  PaymentInfo get _payment => widget.result.payment!;
  String get _orderId => widget.result.order.id;

  @override
  void initState() {
    super.initState();
    _setupCountdown();
    _listenSocket();
    _startPolling();
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
              padding: const EdgeInsets.all(14),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _payment.qrImageUrl,
                      width: 236,
                      height: 236,
                      fit: BoxFit.contain,
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
          const SizedBox(height: 20),
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
        ],
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

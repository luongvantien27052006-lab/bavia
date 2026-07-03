// lib/screens/checkout/qr_payment_screen.dart
//
// Màn thanh toán chuyển khoản QR. Hiển thị VietQR + nội dung CK + đếm ngược.
// Lắng nghe socket "payment.confirmed" để tự nhảy sang màn thành công ngay
// khi backend nhận được tiền (qua webhook Sepay). Có nút kiểm tra thủ công
// làm phương án dự phòng nếu socket lỡ mất kết nối.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/socket_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/repository_providers.dart';
import '../../utils/formatters.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán QR',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(
              expired ? 'Mã QR đã hết hạn' : 'Quét mã để thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: expired ? AppColors.delivery : AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (!expired)
            Center(
              child: Text('Tự động xác nhận • còn $_countdownText',
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5DDD7)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _payment.qrImageUrl,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) => const SizedBox(
                    width: 240,
                    height: 240,
                    child: Icon(Icons.broken_image_rounded,
                        size: 64, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _amountCard(),
          const SizedBox(height: 12),
          _infoCard(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _checking ? null : () => _checkOrderStatus(),
            icon: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            label: const Text('Tôi đã chuyển khoản'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.coffee),
              foregroundColor: AppColors.coffee,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coffee.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Số tiền',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text(Formatters.money(_payment.amount),
              style: const TextStyle(
                  color: AppColors.coffee,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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

  Widget _infoRow(String label, String value, {bool copy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (copy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Đã sao chép'),
                      duration: Duration(seconds: 1)),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.coffee),
              ),
            ),
        ],
      ),
    );
  }
}

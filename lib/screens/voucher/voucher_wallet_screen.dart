// lib/screens/voucher/voucher_wallet_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Ví voucher của khách: chia Khả dụng / Hết hạn.
// Mỗi voucher là 1 "vé" kính: cuống trái ghi mức giảm lớn, đường răng cưa,
// thông tin + nút sao chép mã bên phải.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/voucher_wallet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voucher_wallet_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/anim.dart';
import '../../widgets/stage.dart';
import '../auth/login_screen.dart';

class VoucherWalletScreen extends ConsumerStatefulWidget {
  const VoucherWalletScreen({super.key});
  @override
  ConsumerState<VoucherWalletScreen> createState() =>
      _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends ConsumerState<VoucherWalletScreen> {
  bool _showExpired = false;

  static const _tint = Color(0xFFFF8A1F); // cam ưu đãi
  static const _shipColor = Color(0xFF34C77B);
  static const _discColor = Color(0xFFFF6B4A);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return StageScaffold(
        title: 'Voucher',
        tint: _tint,
        showBack: false,
        body: _guestPrompt(context),
      );
    }

    final async = ref.watch(availableVouchersProvider);
    final usableCount =
        async.valueOrNull?.where((v) => v.isUsable).length ?? 0;

    return StageScaffold(
      title: 'Ví voucher',
      subtitle: usableCount > 0 ? '$usableCount voucher dùng được' : null,
      tint: _tint,
      showBack: false,
      body: RefreshIndicator(
        color: St.fg(),
        backgroundColor: St.refreshBg,
        onRefresh: () async => ref.invalidate(availableVouchersProvider),
        child: async.when(
          loading: () =>  Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: St.fg(0.7))),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                  child: Text('Không tải được voucher. Kéo xuống để thử lại.',
                      style: TextStyle(
                          color: St.fg(0.7)))),
            ],
          ),
          data: (all) {
            final usable = all.where((v) => v.isUsable).toList();
            final expired = all.where((v) => !v.isUsable).toList();
            final list = _showExpired ? expired : usable;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
              children: [
                _segmented(usable.length, expired.length),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  _empty()
                else
                  for (var i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeSlideIn(index: i, child: _ticket(list[i])),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _segmented(int usable, int expired) {
    Widget seg(String label, int count, bool active, VoidCallback onTap) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active ? St.solid : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: active
                              ? St.onSolid
                              : St.fg(0.75))),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: active
                          ? _tint
                          : St.fill(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            color: active ? kOnColor : St.fg(),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: St.fill(0.08),
        border: Border.all(color: St.line(0.12)),
      ),
      child: Row(
        children: [
          seg('Khả dụng', usable, !_showExpired,
              () => setState(() => _showExpired = false)),
          seg('Hết hạn', expired, _showExpired,
              () => setState(() => _showExpired = true)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: St.fill(0.08),
            border: Border.all(color: St.line(0.12)),
          ),
          child: Icon(Icons.confirmation_number_outlined,
              size: 44, color: St.fg(0.8)),
        ),
        const SizedBox(height: 16),
        Text(_showExpired ? 'Không có voucher hết hạn' : 'Chưa có voucher',
            style:  TextStyle(
                color: St.fg(),
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Voucher & ưu đãi sẽ xuất hiện ở đây',
            style: TextStyle(
                color: St.fg(0.6), fontSize: 13)),
      ]),
    );
  }

  Widget _guestPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tint.withValues(alpha: 0.18),
                border: Border.all(color: _tint.withValues(alpha: 0.5)),
              ),
              child:  Icon(Icons.confirmation_number_rounded,
                  color: St.fg(), size: 40),
            ),
            const SizedBox(height: 16),
             Text('Đăng nhập để xem voucher',
                style: TextStyle(
                    color: St.fg(),
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Nhận ngay ưu đãi dành cho khách hàng mới.',
                textAlign: TextAlign.center,
                style: TextStyle(color: St.fg(0.65))),
            const SizedBox(height: 22),
            StageButton(
              label: 'Đăng nhập',
              icon: Icons.login_rounded,
              white: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mức giảm hiển thị lớn trên cuống vé: "15%" / "20K" / "Free".
  String _bigValue(VoucherWallet v, bool isShip) {
    if (v.isPercent) return '${v.discountValue}%';
    if (v.discountValue >= 1000) {
      final k = v.discountValue / 1000;
      return '${k == k.roundToDouble() ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return isShip ? 'Free' : '${v.discountValue}đ';
  }

  Widget _ticket(VoucherWallet v) {
    final isShip = v.type == 'SHIPPING';
    final accent = isShip ? _shipColor : _discColor;
    const stubW = 92.0;

    return Opacity(
      opacity: v.isUsable ? 1 : 0.55,
      child: ClipPath(
        clipper: const _TicketClipper(stubWidth: stubW),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                St.fill(0.11),
                St.fill(0.05),
              ],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cuống vé: mức giảm lớn trên nền màu.
                Container(
                  width: stubW,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(accent, kOnColor, 0.1)!,
                        Color.lerp(accent, Colors.black, 0.3)!,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isShip
                              ? Icons.local_shipping_rounded
                              : Icons.confirmation_number_rounded,
                          color: kOnColor.withValues(alpha: 0.9),
                          size: 20),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(_bigValue(v, isShip),
                            style: const TextStyle(
                                color: kOnColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                      ),
                      Text(isShip ? 'FREESHIP' : 'GIẢM GIÁ',
                          style: TextStyle(
                              color: kOnColor.withValues(alpha: 0.85),
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                // Phần thông tin.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:  TextStyle(
                                color: St.fg(),
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5)),
                        const SizedBox(height: 6),
                        _line(Icons.shopping_bag_outlined,
                            v.minOrderValue > 0
                                ? 'Đơn từ ${Formatters.money(v.minOrderValue)}'
                                : 'Mọi đơn hàng'),
                        _line(Icons.access_time_rounded,
                            v.endDate != null
                                ? 'HSD ${Formatters.date(v.endDate)}'
                                : 'Không thời hạn'),
                        _line(Icons.repeat_rounded,
                            'Còn ${v.remainingForMe}/${v.perUserLimit} lượt'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          St.line(0.25)),
                                ),
                                child: Text(v.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:  TextStyle(
                                        color: St.fg(),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: St.fill(0.14),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: v.code));
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Đã sao chép mã ${v.code}'),
                                        duration: const Duration(seconds: 1)),
                                  );
                                },
                                child:  Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  child: Text('Sao chép',
                                      style: TextStyle(
                                          color: St.fg(),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: St.fg(0.55)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: St.fg(0.75),
                    fontSize: 12.5))),
      ]),
    );
  }
}

/// Khung vé: bo góc + 2 khuyết tròn tại đường cắt cuống + răng cưa dọc.
class _TicketClipper extends CustomClipper<Path> {
  final double stubWidth;
  const _TicketClipper({required this.stubWidth});

  @override
  Path getClip(Size size) {
    const r = 20.0; // bo góc
    const notch = 9.0; // bán kính khuyết
    final x = stubWidth;
    final rect = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(r)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: notch));
    // Răng cưa nhỏ dọc đường cắt.
    for (double y = notch + 6; y < size.height - notch - 4; y += 9) {
      holes.addOval(Rect.fromCircle(center: Offset(x, y), radius: 1.6));
    }
    return Path.combine(PathOperation.difference, rect, holes);
  }

  @override
  bool shouldReclip(covariant _TicketClipper old) =>
      old.stubWidth != stubWidth;
}

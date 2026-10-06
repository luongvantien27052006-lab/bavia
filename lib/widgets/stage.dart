// ============================================================
//  FLUTTER — lib/widgets/stage.dart  (MỚI)
//  Bộ khung "SÂN KHẤU" (Sáng/Tối) dùng chung cho mọi màn (đồng bộ với Trang chủ):
//   - StageScaffold : nền tối + dải cực quang đầu trang + tiêu đề lớn + nút kính.
//   - StageGlass    : thẻ kính (nền trắng trong + viền sáng), có thể bấm.
//   - StageIconButton: nút tròn kính (quay lại, yêu thích, ...).
//   - StageButton   : nút chính dạng viên thuốc, màu theo [tint] (tự chọn chữ
//                     trắng/đậm cho đủ tương phản).
//   - StageChip     : nhãn nhỏ dạng kính.
//   - StageSectionTitle: tiêu đề mục + "Xem thêm".
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import 'anim.dart';
import 'aurora_background.dart';
import 'drink_tint.dart';

/// Trắng cố định — chữ/biểu tượng nằm trên nền MÀU (nút màu, huy hiệu, ảnh).
const kOnColor = Colors.white;

/// Mận rất đậm cố định — chữ trên nền trắng cố định (khung QR...).
const kInk = Color(0xFF1A0F14);

/// Màu chữ/biểu tượng nên dùng trên nền [c] (trắng hoặc mận đậm).
Color stageOn(Color c) => c.computeLuminance() > 0.45 ? kInk : kOnColor;

/// Bảng màu "sân khấu" theo chế độ Sáng/Tối (đọc AppColors.dark).
///  - Tối : nền mận đậm, chữ trắng, thẻ kính trắng trong.
///  - Sáng: nền kem hồng, chữ mận đậm, thẻ kính trắng sữa.
class St {
  St._();

  static bool get dark => AppColors.dark;
  static const _ink = Color(0xFF2A1A20);
  static const _cream = Color(0xFFFBF4F1);

  /// Chữ / biểu tượng chính (a = độ đậm 0..1).
  static Color fg([double a = 1]) => dark
      ? Colors.white.withValues(alpha: a)
      : _ink.withValues(alpha: a >= 1 ? 1 : (a * 1.08).clamp(0.0, 1.0));

  /// Nền thẻ kính / ô bấm.
  static Color fill([double a = 0.1]) => dark
      ? Colors.white.withValues(alpha: a)
      : Colors.white.withValues(alpha: (0.55 + a * 2.2).clamp(0.0, 0.96));

  /// Viền, đường kẻ.
  static Color line([double a = 0.12]) => dark
      ? Colors.white.withValues(alpha: a)
      : _ink.withValues(alpha: (a * 0.55).clamp(0.05, 0.22));

  /// Nút / viên "nổi bật" (trắng trên nền tối, mận đậm trên nền sáng).
  static Color get solid => dark ? Colors.white : _ink;
  static Color get onSolid => dark ? kInk : Colors.white;

  /// Nền màn, nền thanh dưới, nền bảng chọn, nền vòng tải lại.
  static Color get base => dark ? const Color(0xFF140B10) : _cream;
  static Color get surface => dark ? const Color(0xFF1B1016) : Colors.white;
  static Color get sheet => dark ? const Color(0xFF1E1218) : Colors.white;
  static Color get refreshBg => dark ? const Color(0xFF2A1A22) : Colors.white;

  /// Chữ mang màu món: tối -> pha sáng; sáng -> pha đậm cho dễ đọc.
  static Color tint(Color c, double a) => dark
      ? Color.lerp(c, Colors.white, a)!
      : Color.lerp(c, Colors.black, 0.32)!;
}

/// Kiểu thanh trạng thái theo nền.
SystemUiOverlayStyle get stageOverlay => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          AppColors.dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: AppColors.dark ? Brightness.dark : Brightness.light,
    );

class StageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Color tint;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  /// null = tự hiện nút quay lại khi màn có thể pop.
  final bool? showBack;

  /// Chiều cao dải cực quang (tính từ dưới thanh trạng thái).
  final double auroraHeight;

  const StageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.tint = DrinkTint.fallback,
    this.bottomBar,
    this.floatingActionButton,
    this.showBack,
    this.auroraHeight = 190,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    final topPad = MediaQuery.paddingOf(context).top;
    final canPop = showBack ?? Navigator.of(context).canPop();
    final base = DrinkTint.stageInk;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: stageOverlay,
      child: Scaffold(
        backgroundColor: base,
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topPad + auroraHeight,
              child: AuroraBackground(
                tint: tint,
                fadeToBase: true,
                base: base,
                child: const SizedBox.expand(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      canPop ? 10 : 18, topPad + 8, 12, 10),
                  child: Row(
                    children: [
                      if (canPop) ...[
                        StageIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Quay lại',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:  TextStyle(
                                color: St.fg(),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: St.fg(0.7),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final a in actions) ...[
                        const SizedBox(width: 8),
                        a,
                      ],
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StageGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Viền sáng màu (vd mục đang chọn). null = viền trắng mờ.
  final Color? highlight;

  const StageGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    final hl = highlight;
    Widget box = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: hl != null
              ? hl.withValues(alpha: 0.9)
              : St.line(0.12),
          width: hl != null ? 1.6 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hl != null
              ? [hl.withValues(alpha: 0.26), hl.withValues(alpha: 0.08)]
              : [
                  St.fill(0.10),
                  St.fill(0.04),
                ],
        ),
        boxShadow: hl != null
            ? [BoxShadow(color: hl.withValues(alpha: 0.28), blurRadius: 18)]
            : null,
      ),
      child: child,
    );
    if (onTap != null) box = PressEffect(onTap: onTap, child: box);
    return box;
  }
}

class StageIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  const StageIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    return Tooltip(
      message: tooltip,
      child: Material(
        color: St.fill(0.12),
        shape: CircleBorder(
            side: BorderSide(color: St.line(0.16))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: color ?? St.fg(), size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

class StageButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color tint;
  final IconData? icon;
  final bool expand;
  final bool loading;

  /// true = nền trắng chữ đậm (nút phụ nổi bật trên nền tối).
  final bool white;

  const StageButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tint = DrinkTint.fallback,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    final enabled = onTap != null && !loading;
    final fg = white ? St.onSolid : stageOn(tint);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else if (icon != null)
          Icon(icon, color: fg, size: 20),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w800, fontSize: 15.5),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.45,
        child: PressEffect(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: white ? St.solid : null,
              gradient: white
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(tint, Colors.white, 0.10)!,
                        Color.lerp(tint, Colors.black, 0.22)!,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (white ? Colors.black : tint)
                      .withValues(alpha: white ? 0.25 : 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class StageChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const StageChip({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c != null
            ? c.withValues(alpha: 0.2)
            : St.fill(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: (c ?? St.line(1)).withValues(alpha: c != null ? 0.55 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c != null ? St.tint(c, 0.45) : St.fg()),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: c != null
                      ? St.tint(c, 0.55)
                      : St.fg(),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class StageSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const StageSectionTitle(
      {super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:  TextStyle(
                  color: St.fg(),
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(action!,
                  style: TextStyle(
                      color: St.fg(0.8),
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

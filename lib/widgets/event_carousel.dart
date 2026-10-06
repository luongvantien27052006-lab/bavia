// ============================================================
//  FLUTTER — lib/widgets/event_carousel.dart  (MỚI)
//  Băng chuyền "Sự kiện & ưu đãi" cho Trang chủ (nền tối sân khấu):
//   - Thẻ lớn, ảnh banner giữ NGUYÊN khung 16:9 (không che chữ trên banner).
//   - Lướt ngang: ảnh trượt chậm hơn khung (parallax), thẻ bên thu nhỏ nhẹ.
//   - Phần chữ là dải kính tối + nút mũi tên phát sáng theo màu món đang xem.
// ============================================================

import 'package:flutter/material.dart';
import 'stage.dart';

import '../models/news.dart';
import '../utils/formatters.dart';
import 'news_image.dart';

class EventCarousel extends StatefulWidget {
  final List<NewsModel> items;
  final Color tint;
  final ValueChanged<NewsModel> onOpen;

  const EventCarousel({
    super.key,
    required this.items,
    required this.tint,
    required this.onOpen,
  });

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  static const double _infoH = 92;
  static const double _parallax = 36;

  late final PageController _pc = PageController(
    viewportFraction: widget.items.length > 1 ? 0.86 : 1.0,
  );
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  double get _page {
    if (_pc.hasClients && _pc.position.haveDimensions) {
      return _pc.page ?? _index.toDouble();
    }
    return _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final multi = items.length > 1;

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      // Thẻ rộng = 1 trang trừ khoảng cách 2 bên.
      final cardW = multi ? w * 0.86 - 12 : w - 32;
      final imgH = cardW * 9 / 16;
      final h = imgH + _infoH;

      return Column(
        children: [
          SizedBox(
            height: h,
            child: PageView.builder(
              controller: _pc,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _pc,
                builder: (context, _) {
                  final d = (i - _page).clamp(-1.0, 1.0);
                  final scale = 1 - 0.06 * d.abs();
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: _card(items[i], cardW, imgH, d),
                    ),
                  );
                },
              ),
            ),
          ),
          if (multi) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: St.solid
                          .withValues(alpha: i == _index ? 0.95 : 0.28),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    });
  }

  bool _isNew(NewsModel n) {
    final p = n.publishedAt;
    return p != null && DateTime.now().difference(p).inDays < 7;
  }

  Widget _card(NewsModel n, double cardW, double imgH, double d) {
    const radius = 26.0;
    final tint = widget.tint;

    return GestureDetector(
      onTap: () => widget.onOpen(n),
      child: Semantics(
        button: true,
        label: n.title,
        child: Container(
          width: cardW,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: St.fill(0.06),
            border: Border.all(color: St.line(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: cardW,
                  height: imgH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh rộng hơn khung một chút để trượt parallax khi lướt.
                      OverflowBox(
                        maxWidth: cardW + _parallax * 2,
                        minWidth: cardW + _parallax * 2,
                        child: Transform.translate(
                          offset: Offset(-d * _parallax, 0),
                          child: SizedBox(
                            width: cardW + _parallax * 2,
                            height: imgH,
                            child: NewsImage(imageUrl: n.imageUrl),
                          ),
                        ),
                      ),
                      if (_isNew(n))
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: St.line(0.3)),
                            ),
                            child: const Text('MỚI',
                                style: TextStyle(
                                    color: kOnColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6)),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _infoH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:  TextStyle(
                                  color: St.fg(),
                                  fontSize: 15.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.event_rounded,
                                      size: 14,
                                      color:
                                          St.fg(0.6)),
                                  const SizedBox(width: 5),
                                  Text(
                                    Formatters.date(n.publishedAt),
                                    style: TextStyle(
                                      color:
                                          St.fg(0.65),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.lerp(tint, Colors.white, 0.15)!,
                                  Color.lerp(tint, Colors.black, 0.25)!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tint.withValues(alpha: 0.5),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: kOnColor, size: 20),
                          ),
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
}

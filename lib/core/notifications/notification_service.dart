// ============================================================
//  FLUTTER — lib/core/notifications/notification_service.dart  (MỚI)
//  Thông báo CỤC BỘ (local): giờ vàng, nhắc điểm, đơn đang giao.
//  >> CẦN thêm package + cấu hình native (xem hướng dẫn cuối chat).
//  Lưu ý: thông báo TỪ SERVER khi app đã tắt cần Firebase (FCM) riêng.
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Xin quyền (Android 13+ / iOS)
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (_) {}
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'bavia_default',
          'Thông báo Mọng Fruits',
          channelDescription: 'Ưu đãi, đơn hàng, điểm thưởng',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Hiện NGAY — dùng cho "Đơn đang giao" khi app đang chạy.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await init();
      await _plugin.show(id, title, body, _details);
    } catch (_) {}
  }

  /// Báo đơn đang giao.
  Future<void> orderOnTheWay(String orderCode) => showNow(
        id: 2001,
        title: '🛵 Đơn đang giao',
        body: 'Đơn $orderCode đang trên đường tới bạn!',
      );

  /// Hẹn "Ưu đãi giờ vàng" LẶP MỖI NGÀY (mặc định 15:00).
  Future<void> scheduleGoldenHourDaily({int hour = 15, int minute = 0}) async {
    try {
      await init();
      await _plugin.zonedSchedule(
        1001,
        '🔥 Ưu đãi giờ vàng!',
        'Đặt ngay kẻo lỡ ưu đãi hôm nay nhé!',
        _nextInstanceOf(hour, minute),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // lặp hằng ngày
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Nhắc "điểm sắp hết hạn" vào thời điểm cụ thể.
  Future<void> schedulePointsExpiry({
    required int points,
    required DateTime when,
  }) async {
    try {
      await init();
      final t = tz.TZDateTime.from(when, tz.local);
      await _plugin.zonedSchedule(
        1002,
        '⏳ Điểm sắp hết hạn',
        'Bạn còn $points điểm sắp hết hạn — đổi quà ngay!',
        t,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }
}
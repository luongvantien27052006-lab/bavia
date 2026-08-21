// ============================================================
//  FLUTTER — lib/providers/checkin_provider.dart  (MỚI)
//  Điểm danh hằng ngày (streak) — lưu máy.
//  Điểm/quà thực tế cần backend cộng; ở đây theo dõi chuỗi + phần thưởng.
// ============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CheckinState {
  final int streak;
  final String? lastDate;
  final int totalDays;
  const CheckinState({this.streak = 0, this.lastDate, this.totalDays = 0});
}

/// Phần thưởng theo ngày trong chuỗi 7 ngày (ngày 7 = voucher).
const kCheckinRewards = <String>['+10đ', '+10đ', '+20đ', '+20đ', '+30đ', '+50đ', '🎁 Voucher'];

final checkinProvider =
    NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);

class CheckinNotifier extends Notifier<CheckinState> {
  static const _key = 'bavia_checkin';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  CheckinState build() {
    _load();
    return const CheckinState();
  }

  String _fmt(DateTime n) =>
      '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  String get _today => _fmt(DateTime.now());
  String get _yesterday =>
      _fmt(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        state = CheckinState(
          streak: (m['streak'] ?? 0) as int,
          lastDate: m['lastDate'] as String?,
          totalDays: (m['totalDays'] ?? 0) as int,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _storage.write(
          key: _key,
          value: jsonEncode({
            'streak': state.streak,
            'lastDate': state.lastDate,
            'totalDays': state.totalDays,
          }));
    } catch (_) {}
  }

  bool get canCheckInToday => state.lastDate != _today;

  /// Vị trí ngày hiện tại trong chuỗi 7 (0..6).
  int get dayIndex => state.streak <= 0 ? 0 : (state.streak - 1) % 7;

  /// Điểm danh. Trả về phần thưởng (chuỗi) hoặc null nếu đã điểm danh hôm nay.
  String? checkIn() {
    if (!canCheckInToday) return null;
    final newStreak =
        (state.lastDate == _yesterday) ? state.streak + 1 : 1;
    state = CheckinState(
      streak: newStreak,
      lastDate: _today,
      totalDays: state.totalDays + 1,
    );
    _save();
    return kCheckinRewards[(newStreak - 1) % 7];
  }
}
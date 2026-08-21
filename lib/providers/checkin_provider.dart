// ============================================================
//  FLUTTER — lib/providers/checkin_provider.dart  (>> CHÉP ĐÈ)
//  Điểm danh SERVER-SIDE: cộng điểm thật qua API /checkin.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

/// Điểm thưởng theo ngày chuỗi 7 (mặc định; server trả về bản chuẩn).
const kCheckinRewards = <int>[1, 1, 2, 2, 3, 5, 10];

class CheckinState {
  final int streak;
  final bool checkedInToday;
  final List<int> rewards;
  final bool loading;
  const CheckinState({
    this.streak = 0,
    this.checkedInToday = false,
    this.rewards = kCheckinRewards,
    this.loading = true,
  });
  CheckinState copyWith({
    int? streak,
    bool? checkedInToday,
    List<int>? rewards,
    bool? loading,
  }) =>
      CheckinState(
        streak: streak ?? this.streak,
        checkedInToday: checkedInToday ?? this.checkedInToday,
        rewards: rewards ?? this.rewards,
        loading: loading ?? this.loading,
      );
}

final checkinProvider =
    NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);

class CheckinNotifier extends Notifier<CheckinState> {
  @override
  CheckinState build() {
    _load();
    return const CheckinState();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.I.get('/checkin') as Map;
      state = CheckinState(
        streak: (d['streak'] ?? 0) as int,
        checkedInToday: (d['checkedInToday'] ?? false) as bool,
        rewards: (d['rewards'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            kCheckinRewards,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  bool get canCheckInToday => !state.checkedInToday && !state.loading;

  /// Điểm danh -> trả về số điểm nhận được (null nếu đã điểm danh / lỗi).
  Future<int?> checkIn() async {
    if (state.checkedInToday) return null;
    try {
      final d = await ApiClient.I.post('/checkin') as Map;
      final streak = (d['streak'] ?? state.streak) as int;
      if (d['alreadyCheckedIn'] == true) {
        state = state.copyWith(checkedInToday: true, streak: streak);
        return null;
      }
      state = state.copyWith(checkedInToday: true, streak: streak);
      return (d['points'] ?? 0) as int;
    } catch (_) {
      return null;
    }
  }
}
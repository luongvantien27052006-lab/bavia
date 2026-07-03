// ============================================================
//  FLUTTER
//  lib/utils/formatters.dart
//  >> CHEP DE (them Formatters.date)
// ============================================================

// lib/utils/formatters.dart
//
// Tiện ích định dạng tiền VND, số điện thoại E.164, thời gian.

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.decimalPattern('vi_VN');

  /// 45000 → "45.000đ"
  static String money(num amount) => '${_currency.format(amount)}đ';

  /// Chuẩn hoá số VN về E.164 cho Firebase: 0901234567 → +84901234567
  static String toE164(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'[\s.\-()]'), '');
    if (s.startsWith('+')) return s;
    if (s.startsWith('0')) return '+84${s.substring(1)}';
    if (s.startsWith('84')) return '+$s';
    return '+84$s';
  }

  /// +84901234567 → "0901 234 567" để hiển thị
  static String prettyPhone(String e164) {
    var s = e164;
    if (s.startsWith('+84')) s = '0${s.substring(3)}';
    if (s.length == 10) {
      return '${s.substring(0, 4)} ${s.substring(4, 7)} ${s.substring(7)}';
    }
    return s;
  }

  static final _dateTime = DateFormat('HH:mm dd/MM/yyyy', 'vi_VN');
  static String dateTime(DateTime? dt) =>
      dt == null ? '' : _dateTime.format(dt.toLocal());

  static final _date = DateFormat('dd/MM/yyyy', 'vi_VN');
  static String date(DateTime? dt) =>
      dt == null ? '' : _date.format(dt.toLocal());
}
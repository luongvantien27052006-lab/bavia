// lib/models/json_x.dart
//
// Helper đọc JSON linh hoạt. Backend chủ yếu dùng snake_case (image_url,
// final_amount...) nhưng vài chỗ camelCase (accessToken, validationToken).
// Các hàm dưới đọc được mọi biến thể + ép kiểu an toàn, tránh crash khi
// field thiếu hoặc kiểu khác kỳ vọng.

class JsonX {
  JsonX._();

  /// Lấy giá trị đầu tiên không-null trong danh sách key ứng viên.
  static dynamic pick(Map json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) return json[k];
    }
    return null;
  }

  static String str(Map json, List<String> keys, {String fallback = ''}) {
    final v = pick(json, keys);
    return v?.toString() ?? fallback;
  }

  static String? strOrNull(Map json, List<String> keys) {
    final v = pick(json, keys);
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Ép số nguyên an toàn (price, quantity...). Chấp nhận int, double, "45000".
  static int intVal(Map json, List<String> keys, {int fallback = 0}) {
    final v = pick(json, keys);
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString().split('.').first) ?? fallback;
  }

  static double dbl(Map json, List<String> keys, {double fallback = 0}) {
    final v = pick(json, keys);
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static bool boolVal(Map json, List<String> keys, {bool fallback = false}) {
    final v = pick(json, keys);
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static DateTime? dateTime(Map json, List<String> keys) {
    final v = pick(json, keys);
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Lấy 1 sub-map (vd order lồng trong { order: {...} }).
  static Map<String, dynamic>? map(Map json, List<String> keys) {
    final v = pick(json, keys);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Lấy 1 list (vd items).
  static List<dynamic> list(Map json, List<String> keys) {
    final v = pick(json, keys);
    if (v is List) return v;
    return const [];
  }
}

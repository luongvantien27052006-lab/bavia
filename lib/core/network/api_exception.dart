// lib/core/network/api_exception.dart
//
// Exception thống nhất cho toàn bộ tầng network.
// Mọi lỗi từ Dio được chuyển thành ApiException với message tiếng Việt
// thân thiện + giữ lại statusCode/errorCode để UI xử lý theo ngữ cảnh.

import 'package:dio/dio.dart';

enum ApiErrorType {
  timeout,
  noConnection,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  badRequest,
  rateLimited,
  server,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final String? errorCode; // mã lỗi nghiệp vụ từ backend, vd ORDER_ALREADY_PAID

  const ApiException(
    this.message, {
    this.type = ApiErrorType.unknown,
    this.statusCode,
    this.errorCode,
  });

  bool get isAuthError => type == ApiErrorType.unauthorized;

  @override
  String toString() => message;

  /// Chuyển DioException → ApiException với thông điệp dễ hiểu cho người Việt.
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Kết nối quá chậm. Vui lòng kiểm tra mạng và thử lại.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          'Không kết nối được máy chủ. Kiểm tra mạng hoặc thử lại sau.',
          type: ApiErrorType.noConnection,
        );

      case DioExceptionType.badResponse:
        return _fromResponse(e.response);

      case DioExceptionType.cancel:
        return const ApiException('Yêu cầu đã bị huỷ.',
            type: ApiErrorType.unknown);

      default:
        return ApiException(
          'Đã có lỗi xảy ra. Vui lòng thử lại.',
          type: ApiErrorType.unknown,
          statusCode: e.response?.statusCode,
        );
    }
  }

  static ApiException _fromResponse(Response? res) {
    final status = res?.statusCode ?? 0;
    final data = res?.data;

    // Backend trả lỗi dạng { success:false, message, errorCode, statusCode }
    String? message;
    String? errorCode;
    if (data is Map) {
      final m = data['message'];
      if (m is String) {
        message = m;
      } else if (m is List && m.isNotEmpty) {
        message = m.first.toString(); // validation trả mảng message
      }
      errorCode = data['errorCode']?.toString();
    }

    final type = switch (status) {
      400 => ApiErrorType.badRequest,
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      429 => ApiErrorType.rateLimited,
      >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };

    final fallback = switch (status) {
      400 => 'Yêu cầu không hợp lệ.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy dữ liệu.',
      409 => 'Dữ liệu bị xung đột. Vui lòng thử lại.',
      429 => 'Bạn thao tác quá nhanh. Vui lòng chờ một lát.',
      >= 500 => 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      _ => 'Đã có lỗi xảy ra.',
    };

    return ApiException(
      message ?? fallback,
      type: type,
      statusCode: status,
      errorCode: errorCode,
    );
  }
}

// lib/core/network/api_client.dart
//
// HTTP client trung tâm cho toàn app. Trách nhiệm:
//   1. Gắn base URL + timeout từ ApiConfig.
//   2. Tự đính kèm access token vào header Authorization.
//   3. Tự refresh token khi gặp 401 — gom các request đồng thời vào 1 hàng
//      đợi, chỉ refresh 1 lần rồi retry tất cả (tránh refresh nhiều lần).
//   4. Khi refresh thất bại → xoá session + báo lên app để về màn đăng nhập.
//
// Cách dùng: gọi ApiClient.I.get/post/... trong các repository.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient I = ApiClient._internal();

  late final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;

  /// Gọi khi refresh token hỏng/hết hạn → app điều hướng về đăng nhập.
  VoidCallback? onSessionExpired;

  // Quản lý refresh đồng thời
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshWaiters = [];

  bool _initialized = false;

  /// Phải gọi 1 lần ở main() trước runApp().
  void init() {
    if (_initialized) return;
    _initialized = true;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        contentType: 'application/json',
        // Không tự throw cho 4xx — ta xử lý trong interceptor/handler.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (ApiConfig.enableLogging) {
      debugPrint('🌐 ApiClient baseUrl  = ${ApiConfig.baseUrl}');
      debugPrint('🔌 ApiClient socket   = ${ApiConfig.socketUrl}');
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ─── Interceptors ──────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Cho phép bỏ qua auth header (vd login/refresh) bằng extra flag.
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    // Chỉ thử refresh khi: 401 + không phải request auth + chưa retry lần nào.
    if (isUnauthorized && !skipAuth && !alreadyRetried) {
      try {
        final newToken = await _refreshToken();
        if (newToken == null) {
          // Refresh hỏng → kết thúc session
          await _handleSessionExpired();
          return handler.next(err);
        }

        // Retry request gốc với token mới
        final opts = err.requestOptions;
        opts.extra['retried'] = true;
        opts.headers['Authorization'] = 'Bearer $newToken';

        final clone = await _dio.fetch(opts);
        return handler.resolve(clone);
      } catch (_) {
        await _handleSessionExpired();
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  // ─── Refresh logic (gom đồng thời) ─────────────────────────────────

  Future<String?> _refreshToken() async {
    // Nếu đang refresh, request này chờ kết quả thay vì gọi refresh lần nữa.
    if (_isRefreshing) {
      final waiter = Completer<String?>();
      _refreshWaiters.add(waiter);
      return waiter.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _completeWaiters(null);
        return null;
      }

      // Gọi refresh trên Dio "trần" để không lặp interceptor.
      final res = await Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      ).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = res.data;
      if (data is Map &&
          data['accessToken'] is String &&
          data['refreshToken'] is String) {
        await _storage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        final newAccess = data['accessToken'] as String;
        _completeWaiters(newAccess);
        return newAccess;
      }

      _completeWaiters(null);
      return null;
    } catch (_) {
      _completeWaiters(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  void _completeWaiters(String? token) {
    for (final w in _refreshWaiters) {
      if (!w.isCompleted) w.complete(token);
    }
    _refreshWaiters.clear();
  }

  Future<void> _handleSessionExpired() async {
    await _storage.clear();
    onSessionExpired?.call();
  }

  // ─── Public request helpers ────────────────────────────────────────
  //
  // Trả về response.data thô (Map/List). Repository tự parse theo shape
  // thật của từng endpoint. Mọi lỗi → ném ApiException.

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool skipAuth = false,
  }) =>
      _request(() => _dio.get(
            path,
            queryParameters: query,
            options: Options(extra: {'skipAuth': skipAuth}),
          ));

  Future<dynamic> post(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) =>
      _request(() => _dio.post(
            path,
            data: data,
            options: Options(extra: {'skipAuth': skipAuth}),
          ));

  Future<dynamic> patch(String path, {Object? data}) =>
      _request(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _request(() => _dio.delete(path, data: data));

  Future<dynamic> _request(Future<Response> Function() send) async {
    try {
      final res = await send();
      final status = res.statusCode ?? 0;

      // validateStatus cho qua <500, nên 4xx tới đây mà không phải DioException.
      if (status >= 400) {
        throw ApiException.fromDio(
          DioException(
            requestOptions: res.requestOptions,
            response: res,
            type: DioExceptionType.badResponse,
          ),
        );
      }
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi không xác định: $e');
    }
  }
}

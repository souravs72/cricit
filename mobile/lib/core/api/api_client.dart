import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../auth/token_store.dart';

/// Backend error shape: {"error": {"code", "message", "request_id", "field"?}}
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, {this.requestId});

  final int status;
  final String code;
  final String message;
  final String? requestId;

  @override
  String toString() => 'ApiException($status, $code, $message, request_id=$requestId)';
}

/// Attaches the access token and refreshes it once on 401.
/// A single in-flight refresh is shared so parallel requests never rotate the token twice
/// (a second rotation would look like token theft and revoke the session).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._store, this._dio);

  final TokenStore _store;
  final Dio _dio;
  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _store.accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthCall = err.requestOptions.path.startsWith('/v1/auth/');
    if (err.response?.statusCode != 401 || isAuthCall || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }
    final ok = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    if (!ok) return handler.next(err);
    final retry = err.requestOptions..extra['retried'] = true;
    retry.headers['Authorization'] = 'Bearer ${await _store.accessToken()}';
    try {
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refresh() async {
    final refresh = await _store.refreshToken();
    if (refresh == null) return false;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final body = res.data!;
      await _store.save(
        access: body['access_token'] as String,
        refresh: body['refresh_token'] as String,
      );
      return true;
    } on DioException {
      await _store.clear(); // reuse detected or session ended: sign out locally
      return false;
    }
  }
}

ApiException toApiException(DioException e) {
  final data = e.response?.data;
  final err = data is Map<String, dynamic> ? data['error'] as Map<String, dynamic>? : null;
  return ApiException(
    e.response?.statusCode ?? 0,
    (err?['code'] as String?) ?? 'network_error',
    (err?['message'] as String?) ?? 'Check your connection and try again.',
    requestId: err?['request_id'] as String?,
  );
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref.watch(tokenStoreProvider), dio));
  return dio;
});

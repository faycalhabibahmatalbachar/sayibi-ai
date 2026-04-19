import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Client HTTP Dio avec refresh automatique sur 401.
class ApiService {
  ApiService(this._tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.resolvedApiRoot,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await _tokens.getAccess();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = e.requestOptions;
              final t = await _tokens.getAccess();
              req.headers['Authorization'] = 'Bearer $t';
              try {
                final clone = await _dio.fetch(req);
                return handler.resolve(clone);
              } catch (err) {
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  final AuthTokenStore _tokens;
  late final Dio _dio;

  Dio get client => _dio;

  Future<bool> _tryRefresh() async {
    final r = await _tokens.getRefresh();
    if (r == null || r.isEmpty) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: ApiConstants.resolvedApiRoot)).post(
        ApiConstants.authRefresh,
        data: {'refresh_token': r},
      );
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        final d = data['data'] as Map;
        final access = d['access_token'] as String?;
        final refresh = d['refresh_token'] as String?;
        if (access != null && refresh != null) {
          await _tokens.saveTokens(access: access, refresh: refresh);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}

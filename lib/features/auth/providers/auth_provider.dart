import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) => AuthTokenStore());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(authTokenStoreProvider));
});

class AuthState {
  const AuthState({
    this.loading = false,
    this.error,
    this.authenticated = false,
  });

  final bool loading;
  final String? error;
  final bool authenticated;

  AuthState copyWith({bool? loading, String? error, bool? authenticated}) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
      authenticated: authenticated ?? this.authenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final t = await _ref.read(authTokenStoreProvider).getAccess();
    if (t != null && t.isNotEmpty) {
      state = state.copyWith(authenticated: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        await _ref.read(authTokenStoreProvider).saveTokens(
              access: d['access_token'] as String,
              refresh: d['refresh_token'] as String,
            );
        state = state.copyWith(loading: false, authenticated: true);
        return true;
      }
      state = state.copyWith(loading: false, error: data['message']?.toString());
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post(
        ApiConstants.authRegister,
        data: {'email': email, 'password': password, 'name': name},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        if (d['access_token'] != null && d['refresh_token'] != null) {
          await _ref.read(authTokenStoreProvider).saveTokens(
                access: d['access_token'] as String,
                refresh: d['refresh_token'] as String,
              );
          state = state.copyWith(loading: false, authenticated: true);
          return true;
        }
      }
      state = state.copyWith(loading: false, error: data['message']?.toString());
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authTokenStoreProvider).clear();
    state = const AuthState(authenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

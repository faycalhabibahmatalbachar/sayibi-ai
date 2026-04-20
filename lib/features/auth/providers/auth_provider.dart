import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/agent_api_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/http_error_message.dart';
import '../../../core/utils/strip_url_hash.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) => AuthTokenStore());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(authTokenStoreProvider));
});

final agentApiServiceProvider = Provider<AgentApiService>((ref) {
  return AgentApiService(ref.watch(apiServiceProvider).client);
});

class AuthState {
  const AuthState({
    this.loading = false,
    this.error,
    this.authenticated = false,
    this.sessionReady = false,
  });

  final bool loading;
  final String? error;
  final bool authenticated;
  final bool sessionReady;

  AuthState copyWith({
    bool? loading,
    String? error,
    bool? authenticated,
    bool? sessionReady,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
      authenticated: authenticated ?? this.authenticated,
      sessionReady: sessionReady ?? this.sessionReady,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    unawaited(_bootstrap());
  }

  final Ref _ref;
  final Completer<void> _bootstrapCompleter = Completer<void>();

  /// Attend la fin de la restauration des jetons (splash / routes).
  Future<void> waitUntilSessionReady() => _bootstrapCompleter.future;

  Future<void> _bootstrap() async {
    try {
      await _restore();
    } finally {
      state = state.copyWith(sessionReady: true);
      if (!_bootstrapCompleter.isCompleted) {
        _bootstrapCompleter.complete();
      }
    }
  }

  Future<void> _restore() async {
    final t = await _ref.read(authTokenStoreProvider).getAccess();
    if (t != null && t.isNotEmpty) {
      state = state.copyWith(authenticated: true);
      await _syncFcmToken();
    }
  }

  Future<void> _syncFcmToken() async {
    try {
      await NotificationService().init();
      final token = NotificationService().fcmToken;
      if (token == null || token.isEmpty) return;
      final dio = _ref.read(apiServiceProvider).client;
      await dio.post(
        ApiConstants.userFcmToken,
        data: {'token': token},
      );
    } catch (_) {
      // Best effort : ne bloque jamais auth.
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
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
        final store = _ref.read(authTokenStoreProvider);
        await store.saveTokens(
          access: d['access_token'] as String,
          refresh: d['refresh_token'] as String,
          persistSession: rememberMe,
        );
        if (rememberMe && email.trim().isNotEmpty) {
          await store.saveLastEmail(email.trim());
        }
        await _syncFcmToken();
        state = state.copyWith(loading: false, authenticated: true);
        return true;
      }
      state = state.copyWith(loading: false, error: data['message']?.toString());
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: httpErrorMessage(e));
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name, {
    bool rememberMe = true,
  }) async {
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
          final store = _ref.read(authTokenStoreProvider);
          await store.saveTokens(
            access: d['access_token'] as String,
            refresh: d['refresh_token'] as String,
            persistSession: rememberMe,
          );
          if (rememberMe && email.trim().isNotEmpty) {
            await store.saveLastEmail(email.trim());
          }
          await _syncFcmToken();
          state = state.copyWith(loading: false, authenticated: true);
          return true;
        }
      }
      state = state.copyWith(loading: false, error: data['message']?.toString());
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: httpErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authTokenStoreProvider).clear();
    state = const AuthState(sessionReady: true);
  }

  /// Après clic sur le lien de confirmation Supabase (`…#access_token=…`).
  /// `null` = pas de fragment à traiter ; `true` = session enregistrée ; `false` = échec.
  Future<bool?> tryCompleteSupabaseEmailRedirect() async {
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty || !fragment.contains('access_token')) {
      return null;
    }
    final q = Uri.splitQueryString(fragment);
    final sat = q['access_token'];
    if (sat == null || sat.isEmpty) {
      return null;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post(
        ApiConstants.authSupabaseSession,
        data: {'supabase_access_token': sat},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        await _ref.read(authTokenStoreProvider).saveTokens(
              access: d['access_token'] as String,
              refresh: d['refresh_token'] as String,
              persistSession: true,
            );
        await _syncFcmToken();
        state = state.copyWith(loading: false, authenticated: true);
        if (kIsWeb) {
          stripAuthFragmentFromBrowserUrl();
        }
        return true;
      }
      state = state.copyWith(
        loading: false,
        error: data['message']?.toString() ?? 'Confirmation impossible',
      );
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: httpErrorMessage(e));
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

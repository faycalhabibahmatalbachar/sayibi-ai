import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState {
  const ProfileState({
    this.loading = false,
    this.saving = false,
    this.notifySending = false,
    this.error,
    this.user,
    this.usage,
    this.files,
  });

  final bool loading;
  final bool saving;
  final bool notifySending;
  final String? error;

  /// Données brutes `GET /user/profile` → `data`.
  final Map<String, dynamic>? user;

  /// `GET /user/usage` → `data`.
  final Map<String, dynamic>? usage;

  /// `GET /user/files` → `data` (generated + documents).
  final Map<String, dynamic>? files;

  int get generatedCount {
    final g = files?['generated'];
    if (g is List) return g.length;
    return 0;
  }

  int get documentsCount {
    final d = files?['documents'];
    if (d is List) return d.length;
    return 0;
  }

  ProfileState copyWith({
    bool? loading,
    bool? saving,
    bool? notifySending,
    Object? error = _sentinel,
    Map<String, dynamic>? user,
    Map<String, dynamic>? usage,
    Map<String, dynamic>? files,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      notifySending: notifySending ?? this.notifySending,
      error: identical(error, _sentinel) ? this.error : error as String?,
      user: user ?? this.user,
      usage: usage ?? this.usage,
      files: files ?? this.files,
    );
  }

  static const Object _sentinel = Object();
}

Map<String, dynamic>? _dataIfOk(Response<dynamic> res) {
  final body = res.data;
  if (body is Map && body['success'] == true && body['data'] != null) {
    final d = body['data'];
    if (d is Map) {
      return Map<String, dynamic>.from(d);
    }
  }
  return null;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileState());

  final Ref _ref;

  Future<void> refresh({bool quiet = false}) async {
    if (!_ref.read(authProvider).authenticated) {
      state = const ProfileState();
      return;
    }
    if (!quiet) {
      state = state.copyWith(loading: true, error: null);
    }
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final p = await dio.get<dynamic>(ApiConstants.userProfile);
      final u = await dio.get<dynamic>(ApiConstants.userUsage);
      final f = await dio.get<dynamic>(ApiConstants.userFiles);
      state = state.copyWith(
        loading: false,
        user: _dataIfOk(p),
        usage: _dataIfOk(u),
        files: _dataIfOk(f),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> saveSettings({
    String? language,
    String? theme,
    bool? notifications,
    String? modelPreference,
  }) async {
    state = state.copyWith(saving: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final body = <String, dynamic>{};
      if (language != null) body['language'] = language;
      if (theme != null) body['theme'] = theme;
      if (notifications != null) body['notifications'] = notifications;
      if (modelPreference != null) body['model_preference'] = modelPreference;
      if (body.isEmpty) {
        state = state.copyWith(saving: false);
        return true;
      }
      final res = await dio.put<Map<String, dynamic>>(
        ApiConstants.userSettings,
        data: body,
      );
      final bodyMap = res.data;
      if (bodyMap is Map<String, dynamic> && bodyMap['success'] == true) {
        await refresh(quiet: true);
        state = state.copyWith(saving: false);
        return true;
      }
      final err = bodyMap is Map<String, dynamic> ? bodyMap['message']?.toString() : null;
      state = state.copyWith(
        saving: false,
        error: err,
      );
      return false;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<String?> sendTestNotification() async {
    state = state.copyWith(notifySending: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post<Map<String, dynamic>>(
        ApiConstants.userNotifyTest,
        data: {},
      );
      final bodyMap = res.data;
      state = state.copyWith(notifySending: false);
      if (bodyMap is Map<String, dynamic> && bodyMap['success'] == true) {
        return null;
      }
      final fail = bodyMap is Map<String, dynamic> ? bodyMap['message']?.toString() : null;
      return fail ?? 'Échec';
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      state = state.copyWith(notifySending: false, error: msg ?? e.message);
      return msg ?? e.message;
    } catch (e) {
      state = state.copyWith(notifySending: false, error: e.toString());
      return e.toString();
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier(ref));

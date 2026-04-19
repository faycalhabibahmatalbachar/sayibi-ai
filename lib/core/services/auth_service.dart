import 'package:shared_preferences/shared_preferences.dart';

/// Stockage persistant des jetons (complément Hive pour clés sensibles simples).
class AuthTokenStore {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setString(_kRefresh, refresh);
  }

  Future<String?> getAccess() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  Future<String?> getRefresh() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }
}

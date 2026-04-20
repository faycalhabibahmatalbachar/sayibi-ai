import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage des jetons : Secure Storage (mobile) ou SharedPreferences (web),
/// avec option « session seulement » (sans persistance au redémarrage).
class AuthTokenStore {
  static const _kAccessLegacy = 'access_token';
  static const _kRefreshLegacy = 'refresh_token';
  static const _kRemember = 'auth_remember_me';
  static const _kAccessSecure = 'sayibi_access_token';
  static const _kRefreshSecure = 'sayibi_refresh_token';
  static const _kLastEmail = 'auth_last_email';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _memAccess;
  String? _memRefresh;

  Future<bool> getRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRemember) ?? true;
  }

  Future<void> saveLastEmail(String email) async {
    final p = await SharedPreferences.getInstance();
    if (email.isEmpty) {
      await p.remove(_kLastEmail);
    } else {
      await p.setString(_kLastEmail, email);
    }
  }

  Future<String?> getLastEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLastEmail);
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
    required bool persistSession,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, persistSession);

    if (kIsWeb) {
      await p.remove(_kAccessLegacy);
      await p.remove(_kRefreshLegacy);
      if (persistSession) {
        _memAccess = null;
        _memRefresh = null;
        await p.setString(_kAccessLegacy, access);
        await p.setString(_kRefreshLegacy, refresh);
      } else {
        _memAccess = access;
        _memRefresh = refresh;
      }
      return;
    }

    await p.remove(_kAccessLegacy);
    await p.remove(_kRefreshLegacy);

    if (persistSession) {
      _memAccess = null;
      _memRefresh = null;
      await _secure.write(key: _kAccessSecure, value: access);
      await _secure.write(key: _kRefreshSecure, value: refresh);
    } else {
      await _secure.delete(key: _kAccessSecure);
      await _secure.delete(key: _kRefreshSecure);
      _memAccess = access;
      _memRefresh = refresh;
    }
  }

  Future<void> _migrateLegacyIfNeeded() async {
    if (kIsWeb) return;
    final p = await SharedPreferences.getInstance();
    final legacyA = p.getString(_kAccessLegacy);
    if (legacyA == null || legacyA.isEmpty) return;
    final existing = await _secure.read(key: _kAccessSecure);
    if (existing != null && existing.isNotEmpty) {
      await p.remove(_kAccessLegacy);
      await p.remove(_kRefreshLegacy);
      return;
    }
    final legacyR = p.getString(_kRefreshLegacy);
    await _secure.write(key: _kAccessSecure, value: legacyA);
    if (legacyR != null && legacyR.isNotEmpty) {
      await _secure.write(key: _kRefreshSecure, value: legacyR);
    }
    await p.remove(_kAccessLegacy);
    await p.remove(_kRefreshLegacy);
  }

  Future<String?> getAccess() async {
    final remember = await getRememberMe();
    if (!remember) {
      return _memAccess;
    }
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_kAccessLegacy);
    }
    await _migrateLegacyIfNeeded();
    return _secure.read(key: _kAccessSecure);
  }

  Future<String?> getRefresh() async {
    final remember = await getRememberMe();
    if (!remember) {
      return _memRefresh;
    }
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_kRefreshLegacy);
    }
    await _migrateLegacyIfNeeded();
    return _secure.read(key: _kRefreshSecure);
  }

  Future<void> clear() async {
    _memAccess = null;
    _memRefresh = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccessLegacy);
    await p.remove(_kRefreshLegacy);
    if (!kIsWeb) {
      await _secure.delete(key: _kAccessSecure);
      await _secure.delete(key: _kRefreshSecure);
    }
    await p.setBool(_kRemember, true);
  }
}

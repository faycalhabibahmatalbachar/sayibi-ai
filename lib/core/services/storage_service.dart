import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'sayibi_cache';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> put(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  T? get<T>(String key) {
    final v = _box?.get(key);
    return v is T ? v : null;
  }

  Future<void> delete(String key) async {
    await _box?.delete(key);
  }
}

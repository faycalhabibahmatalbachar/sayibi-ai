import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Recherche locale de fichiers (gestionnaire de fichiers) avec index persistant.
class LocalFileService {
  LocalFileService._();

  static const Duration _maxIndexAge = Duration(hours: 6);
  static const int _defaultMaxIndexedFiles = 5000;
  static const Set<String> _skipDirs = {
    'android',
    '.thumbnails',
    '.trash',
    'dcim/.thumbnails',
  };

  static Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;
    var storage = await Permission.storage.status;
    if (!storage.isGranted) storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    // Android 11+ : certains appareils exigent MANAGE_EXTERNAL_STORAGE.
    var manage = await Permission.manageExternalStorage.status;
    if (!manage.isGranted) manage = await Permission.manageExternalStorage.request();
    return manage.isGranted;
  }

  static Future<File> _indexFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'local_file_index_v1.json'));
  }

  static List<Directory> _candidateRoots() {
    if (!Platform.isAndroid) return const [];
    final root = Directory('/storage/emulated/0');
    final names = <String>[
      'Download',
      'Documents',
      'WhatsApp',
      'Telegram',
      'Movies',
      'Music',
      'Pictures',
      'DCIM',
    ];
    return names.map((n) => Directory(p.join(root.path, n))).toList();
  }

  static String _kindFromExt(String ext) {
    final e = ext.toLowerCase();
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.heic',
      '.bmp',
    ].contains(e)) {
      return 'image';
    }
    if (['.mp4', '.mkv', '.mov', '.avi', '.3gp', '.webm'].contains(e)) {
      return 'video';
    }
    if (['.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'].contains(e)) {
      return 'audio';
    }
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].contains(e)) {
      return 'document';
    }
    if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(e)) {
      return 'archive';
    }
    return 'file';
  }

  static Future<void> _saveIndex(Map<String, dynamic> data) async {
    final f = await _indexFile();
    await f.writeAsString(jsonEncode(data), flush: true);
  }

  static Future<Map<String, dynamic>?> _loadIndex() async {
    try {
      final f = await _indexFile();
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isSkippableDir(String path) {
    final low = path.replaceAll('\\', '/').toLowerCase();
    for (final s in _skipDirs) {
      if (low.contains('/$s')) return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> refreshIndex({
    bool force = false,
    int maxFiles = _defaultMaxIndexedFiles,
  }) async {
    if (!await ensurePermission()) {
      return {'ok': false, 'reason': 'permission_denied', 'count': 0};
    }
    final existing = await _loadIndex();
    if (!force &&
        existing != null &&
        existing['updated_at'] is String &&
        DateTime.tryParse(existing['updated_at'] as String) != null) {
      final updatedAt = DateTime.parse(existing['updated_at'] as String);
      if (DateTime.now().difference(updatedAt) < _maxIndexAge) {
        final items = existing['items'] is List ? existing['items'] as List : const [];
        return {'ok': true, 'count': items.length, 'cached': true};
      }
    }

    final items = <Map<String, dynamic>>[];
    for (final root in _candidateRoots()) {
      if (!root.existsSync()) continue;
      try {
        await for (final entity in root.list(recursive: true, followLinks: false)) {
          if (items.length >= maxFiles) break;
          if (entity is Directory) {
            if (_isSkippableDir(entity.path)) {
              continue;
            }
            continue;
          }
          if (entity is! File) continue;
          final stat = await entity.stat();
          final name = p.basename(entity.path);
          final ext = p.extension(entity.path).toLowerCase();
          items.add({
            'path': entity.path,
            'name': name,
            'ext': ext,
            'kind': _kindFromExt(ext),
            'size': stat.size,
            'modified_at': stat.modified.toIso8601String(),
          });
        }
      } catch (_) {
        // Dossier inaccessible: on continue les autres racines.
      }
      if (items.length >= maxFiles) break;
    }

    await _saveIndex({
      'updated_at': DateTime.now().toIso8601String(),
      'items': items,
    });
    return {'ok': true, 'count': items.length, 'cached': false};
  }

  static bool _matchesKind(String itemKind, String filter) {
    if (filter == 'any' || filter.isEmpty) return true;
    return itemKind == filter;
  }

  static Future<List<Map<String, dynamic>>> searchFiles(
    String query, {
    int limit = 20,
    String kind = 'any',
    bool refreshIfStale = true,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    if (!await ensurePermission()) return [];
    if (refreshIfStale) await refreshIndex(force: false);

    final idx = await _loadIndex();
    final source = idx?['items'] is List ? (idx!['items'] as List) : const [];
    final rows = source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (rows.isEmpty) return [];

    final terms = q.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final kindFilter = kind.toLowerCase();

    double score(Map<String, dynamic> item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final ext = (item['ext'] ?? '').toString().toLowerCase();
      var s = 0.0;
      if (name == q) s += 6;
      if (name.contains(q)) s += 3;
      for (final t in terms) {
        if (name.contains(t)) s += 1.2;
      }
      if (q.startsWith('.') && ext == q) s += 2;
      final modified = DateTime.tryParse((item['modified_at'] ?? '').toString());
      if (modified != null) {
        final daysOld = DateTime.now().difference(modified).inDays;
        if (daysOld <= 30) s += 0.8;
      }
      return s;
    }

    List<Map<String, dynamic>> runFilter(List<Map<String, dynamic>> input) {
      return input.where((item) {
        final path = (item['path'] ?? '').toString();
        if (path.isEmpty || !File(path).existsSync()) return false;
        final itemKind = (item['kind'] ?? 'file').toString().toLowerCase();
        if (!_matchesKind(itemKind, kindFilter)) return false;
        final name = (item['name'] ?? '').toString().toLowerCase();
        final textMatch = name.contains(q) || terms.every((t) => name.contains(t));
        return textMatch;
      }).toList();
    }

    var filtered = runFilter(rows);
    // Robustesse: si vide, forcer un refresh immédiat une fois puis retenter.
    if (filtered.isEmpty && refreshIfStale) {
      await refreshIndex(force: true);
      final fresh = await _loadIndex();
      final freshRows = fresh?['items'] is List
          ? (fresh!['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      filtered = runFilter(freshRows);
    }

    filtered.sort((a, b) => score(b).compareTo(score(a)));
    return filtered.take(limit).map((e) {
      final s = score(e);
      return {
        ...e,
        'score': double.parse(s.toStringAsFixed(2)),
      };
    }).toList();
  }
}

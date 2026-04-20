import 'dart:io';
import 'dart:convert';

import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMediaService {
  LocalMediaService._();

  static const Duration _maxIndexAge = Duration(hours: 6);

  static Future<bool> ensurePermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.hasAccess;
  }

  static Future<File> _indexFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'local_media_index_v1.json'));
  }

  static Future<Map<String, dynamic>> refreshIndex({
    bool force = false,
    int maxAssets = 1200,
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

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
        videoOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (paths.isEmpty) {
      await _saveIndex({'updated_at': DateTime.now().toIso8601String(), 'items': <Map<String, dynamic>>[]});
      return {'ok': true, 'count': 0, 'cached': false};
    }

    final pageSize = 200;
    final items = <Map<String, dynamic>>[];
    var page = 0;
    while (items.length < maxAssets) {
      final batch = await paths.first.getAssetListPaged(page: page, size: pageSize);
      if (batch.isEmpty) break;
      for (final a in batch) {
        final file = await a.file;
        if (file == null) continue;
        final mediaPath = file.path;
        if (mediaPath.isEmpty || !File(mediaPath).existsSync()) continue;
        items.add({
          'id': a.id,
          'title': a.title ?? (a.type == AssetType.video ? 'Video' : 'Image'),
          'path': mediaPath,
          'type': a.type == AssetType.video ? 'video' : 'image',
          'width': a.width,
          'height': a.height,
          'duration_sec': a.duration,
          'created_at': a.createDateTime.toIso8601String(),
        });
        if (items.length >= maxAssets) break;
      }
      page += 1;
    }

    await _saveIndex({
      'updated_at': DateTime.now().toIso8601String(),
      'items': items,
    });
    return {'ok': true, 'count': items.length, 'cached': false};
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

  static Future<void> _saveIndex(Map<String, dynamic> data) async {
    final f = await _indexFile();
    await f.writeAsString(jsonEncode(data), flush: true);
  }

  static Future<List<Map<String, dynamic>>> searchMedia(
    String query, {
    int limit = 12,
    String mediaType = 'any',
    DateTime? dateFrom,
    DateTime? dateTo,
    bool refreshIfStale = true,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    if (!await ensurePermission()) return [];

    if (refreshIfStale) {
      await refreshIndex(force: false);
    }
    final idx = await _loadIndex();
    final source = idx?['items'] is List ? (idx!['items'] as List) : const [];
    final rows = source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (rows.isEmpty) return [];

    final terms = q.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final normalizedType = mediaType.toLowerCase();

    double score(Map<String, dynamic> item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      var s = 0.0;
      if (title == q) s += 5;
      if (title.contains(q)) s += 3;
      for (final t in terms) {
        if (title.contains(t)) s += 1.2;
      }
      final created = DateTime.tryParse((item['created_at'] ?? '').toString());
      if (created != null) {
        final daysOld = DateTime.now().difference(created).inDays;
        if (daysOld <= 30) s += 0.8;
      }
      if ((item['type'] ?? '').toString() == 'video') s += 0.1;
      return s;
    }

    final filtered = rows.where((item) {
      final type = (item['type'] ?? '').toString();
      if (normalizedType == 'image' && type != 'image') return false;
      if (normalizedType == 'video' && type != 'video') return false;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final textMatch = title.contains(q) || terms.every((t) => title.contains(t));
      if (!textMatch) return false;
      final created = DateTime.tryParse((item['created_at'] ?? '').toString());
      if (dateFrom != null && created != null && created.isBefore(dateFrom)) return false;
      if (dateTo != null && created != null && created.isAfter(dateTo)) return false;
      final path = (item['path'] ?? '').toString();
      if (path.isEmpty || !File(path).existsSync()) return false;
      return true;
    }).toList();

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


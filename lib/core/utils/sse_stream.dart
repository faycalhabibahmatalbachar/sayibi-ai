import 'dart:convert';

import 'package:dio/dio.dart';

/// Décode un flux SSE (`text/event-stream`) en cartes JSON par événement `data:`.
Stream<Map<String, dynamic>> parseSseJsonStream(ResponseBody body) async* {
  var pending = '';
  await for (final chunk in utf8.decoder.bind(body.stream)) {
    pending += chunk;
    while (true) {
      final i = pending.indexOf('\n\n');
      if (i < 0) break;
      final block = pending.substring(0, i);
      pending = pending.substring(i + 2);
      for (final line in block.split('\n')) {
        final t = line.trimRight();
        if (t.startsWith('data:')) {
          final jsonStr = t.substring(5).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final obj = jsonDecode(jsonStr);
            if (obj is Map<String, dynamic>) {
              yield obj;
            }
          } catch (_) {
            // ignore malformed chunk
          }
        }
      }
    }
  }
}

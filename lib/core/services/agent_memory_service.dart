import 'dart:convert';

import 'storage_service.dart';

class AgentMemoryService {
  AgentMemoryService._();

  static const String _smsHistoryKey = 'agent_sms_history_v1';
  static const String _smsHistorySessionPrefix = 'agent_sms_history_session_v1_';
  static const int _maxSmsEntries = 120;

  static Future<void> recordSmsAction({
    required String toE164,
    required String body,
    bool sent = true,
    bool usedSimDirect = true,
    String? contactId,
    String? contactName,
    String? sessionId,
  }) async {
    final current = getSmsHistory();
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'to': toE164,
      'to_masked': _maskPhone(toE164),
      'body': body.trim(),
      'body_preview': _preview(body),
      'contact_id': contactId,
      'contact_name': (contactName ?? '').trim(),
      'sent': sent,
      'used_sim_direct': usedSimDirect,
    };
    current.insert(0, entry);
    if (current.length > _maxSmsEntries) {
      current.removeRange(_maxSmsEntries, current.length);
    }
    await LocalStorageService.instance.put(
      _smsHistoryKey,
      jsonEncode(current),
    );

    if (sessionId != null && sessionId.trim().isNotEmpty) {
      final sk = _sessionKey(sessionId);
      final sessionRows = getSmsHistory(sessionId: sessionId);
      sessionRows.insert(0, entry);
      if (sessionRows.length > _maxSmsEntries) {
        sessionRows.removeRange(_maxSmsEntries, sessionRows.length);
      }
      await LocalStorageService.instance.put(sk, jsonEncode(sessionRows));
    }
  }

  static List<Map<String, dynamic>> getSmsHistory({String? sessionId}) {
    final raw = LocalStorageService.instance.get<String>(
      sessionId != null && sessionId.trim().isNotEmpty
          ? _sessionKey(sessionId)
          : _smsHistoryKey,
    );
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  /// Contexte mémoire injecté au backend agent.
  static String buildSmsMemoryContext({
    String? sessionId,
    int maxEntries = 6,
    List<Map<String, dynamic>>? remoteSmsActions,
  }) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    final sessionEntries = getSmsHistory(sessionId: sessionId);
    final globalEntries = getSmsHistory();
    for (final e in [...sessionEntries, ...globalEntries]) {
      final key = '${e['timestamp']}|${e['to']}|${e['body_preview']}';
      if (seen.add(key)) merged.add(e);
      if (merged.length >= maxEntries) break;
    }

    final entries = merged.take(maxEntries).toList();
    final remote = remoteSmsActions ?? <Map<String, dynamic>>[];
    if (entries.isEmpty) return 'Aucune action SMS mémorisée localement.';
    final lines = <String>[];
    for (final e in entries) {
      final at = e['timestamp']?.toString() ?? '';
      final toMasked = e['to_masked']?.toString() ?? '•••';
      final name = (e['contact_name']?.toString() ?? '').trim();
      final preview = e['body_preview']?.toString() ?? '';
      final sent = e['sent'] == true ? 'envoye' : 'echec';
      final channel = e['used_sim_direct'] == true ? 'SIM' : 'composeur';
      lines.add(
        '- [$at] sms $sent vers ${name.isNotEmpty ? "$name ($toMasked)" : toMasked} via $channel: "$preview"',
      );
    }
    if (remote.isNotEmpty) {
      lines.add('- Historique serveur recent:');
      for (final r in remote.take(4)) {
        final at = r['created_at']?.toString() ?? '';
        final to = r['phone_masked']?.toString() ?? '•••';
        final status = r['status']?.toString() ?? 'unknown';
        final preview = r['message_preview']?.toString() ?? '';
        lines.add('- [$at] sms $status vers $to: "$preview"');
      }
    }
    return lines.join('\n');
  }

  /// Réponse locale directe quand l'utilisateur demande la mémoire d'envoi SMS.
  static String? resolveMemoryQuestion(String userText, {String? sessionId}) {
    final t = userText.trim().toLowerCase();
    final asksAboutSentMessage = t.contains('quel message') ||
        t.contains('message tu as envoy') ||
        t.contains('tu as envoy') ||
        t.contains('as-tu envoy') ||
        t.contains('as tu envoy') ||
        t.contains('dernier sms') ||
        t.contains('quel sms') ||
        t.contains('a qui as tu envoy');
    if (!asksAboutSentMessage) return null;

    final entries = [
      ...getSmsHistory(sessionId: sessionId),
      ...getSmsHistory(),
    ];
    if (entries.isEmpty) {
      return 'Je n’ai aucun SMS enregistré dans ma mémoire locale pour cette session.';
    }

    Map<String, dynamic>? match;
    for (final e in entries) {
      final contactName = (e['contact_name']?.toString() ?? '').toLowerCase();
      if (contactName.isNotEmpty && t.contains(contactName)) {
        match = e;
        break;
      }
    }
    match ??= entries.first;
    final name = (match['contact_name']?.toString() ?? '').trim();
    final to = match['to_masked']?.toString() ?? '•••';
    final preview = match['body']?.toString() ?? '';
    final sent = match['sent'] == true;
    final status = sent ? 'envoye' : 'non envoye';
    final at = match['timestamp']?.toString() ?? '';
    return 'Dernier SMS $status ${name.isNotEmpty ? "a $name ($to)" : "a $to"} le $at : "$preview"';
  }

  static String _sessionKey(String sessionId) =>
      '$_smsHistorySessionPrefix${sessionId.trim()}';

  static String _preview(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 180) return clean;
    return '${clean.substring(0, 180)}…';
  }

  static String _maskPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length < 6) return '•••';
    final tail = d.substring(d.length - 2);
    return '${raw.startsWith('+') ? '+' : ''}${d.substring(0, d.length > 4 ? 4 : 2)} ••• •• $tail';
  }
}

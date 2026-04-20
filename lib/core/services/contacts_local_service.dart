import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Recherche locale de contacts (Android / iOS). Web : liste vide.
class ContactsLocalService {
  ContactsLocalService._();

  static String _maskPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length < 8) return '•••';
    final tail = d.substring(d.length - 2);
    return '${raw.startsWith('+') ? '+' : ''}${d.substring(0, d.length > 4 ? 4 : 2)} ••• •• $tail';
  }

  /// Demande la permission si besoin ; renvoie false si refusée.
  static Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    final s = await Permission.contacts.request();
    return s.isGranted;
  }

  /// Correspondance simple sur le nom affiché (insensible à la casse).
  static Future<List<Map<String, dynamic>>> searchContacts(
    String query, {
    bool fuzzy = true,
  }) async {
    if (kIsWeb || query.trim().isEmpty) return [];
    if (!await ensurePermission()) return [];

    final q = query.trim().toLowerCase();
    final all = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    bool match(String? name) {
      if (name == null || name.isEmpty) return false;
      final n = name.toLowerCase();
      if (fuzzy) {
        return n.contains(q) || q.split(' ').every((p) => p.isEmpty || n.contains(p));
      }
      return n == q;
    }

    final out = <Map<String, dynamic>>[];
    for (final c in all) {
      if (!match(c.displayName)) continue;
      final phones = c.phones.map((p) => p.number).where((n) => n.isNotEmpty).toList();
      if (phones.isEmpty) continue;
      final primary = phones.first;
      final orgs = c.organizations;
      out.add({
        'contact_id': c.id,
        'display_name': c.displayName,
        'company': orgs.isNotEmpty ? orgs.first.company : '',
        'phone_preview': _maskPhone(primary),
        'phone_numbers': [
          for (var i = 0; i < c.phones.length; i++)
            {
              'number': c.phones[i].number,
              'label': c.phones[i].label.name,
              'is_primary': i == 0,
            }
        ],
      });
      if (out.length >= 25) break;
    }
    return out;
  }

  static Future<Map<String, dynamic>?> getContactDetails(String contactId) async {
    if (kIsWeb) return null;
    if (!await ensurePermission()) return null;
    final c = await FlutterContacts.getContact(contactId);
    if (c == null) return null;
    return {
      'contact_id': c.id,
      'display_name': c.displayName,
      'phone_numbers': [
        for (final p in c.phones)
          {
            'number': p.number,
            'label': p.label.name,
          }
      ],
    };
  }
}

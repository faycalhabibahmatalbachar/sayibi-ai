import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

/// Envoi SMS via la carte SIM (Android) — aucun fournisseur cloud type Twilio.
/// iOS : ouverture de Messages avec texte prérempli (pas d’envoi silencieux).
/// Web : non supporté.
class SimSmsService {
  SimSmsService._();

  /// Corps utilisable en SMS (retire le markdown le plus courant).
  static String plainBodyFromAssistantText(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'^```[\s\S]*?```', multiLine: true), '');
    s = s.replaceAll(RegExp(r'[*_`#]'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Future<SimSmsResult> send({
    required String toE164,
    required String body,
  }) async {
    final bodyTrim = body.trim();
    if (bodyTrim.isEmpty) {
      return SimSmsResult.failure('Message vide.');
    }
    if (kIsWeb) {
      return SimSmsResult.failure(
        'Le navigateur ne peut pas accéder à la carte SIM. Utilisez l’application sur Android.',
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return _sendIosComposer(toE164: toE164, body: bodyTrim);
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return SimSmsResult.failure('Plateforme non prise en charge.');
    }

    final perm = await Permission.sms.request();
    if (!perm.isGranted) {
      return SimSmsResult.failure(
        'Permission SMS refusée. Activez-la dans les paramètres de l’application.',
      );
    }

    try {
      final telephony = Telephony.instance;
      final dest = toE164.replaceAll(RegExp(r'[^\d+]'), '');
      await telephony.sendSms(
        to: dest.startsWith('+') ? dest.substring(1) : dest,
        message: bodyTrim,
      );
      return SimSmsResult.ok();
    } on PlatformException catch (e) {
      return SimSmsResult.failure(e.message ?? 'Envoi SMS impossible.');
    } catch (e) {
      return SimSmsResult.failure(e.toString());
    }
  }

  static Future<SimSmsResult> _sendIosComposer({
    required String toE164,
    required String body,
  }) async {
    final digits = toE164.replaceAll(RegExp(r'[^\d+]'), '');
    final path = digits.startsWith('+') ? digits : '+$digits';
    final uri = Uri(
      scheme: 'sms',
      path: path,
      queryParameters: <String, String>{'body': body},
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      return SimSmsResult.failure('Impossible d’ouvrir Messages.');
    }
    return SimSmsResult.openedComposer();
  }
}

class SimSmsResult {
  SimSmsResult._({
    required this.ok,
    required this.usedSimDirect,
    this.message,
  });

  final bool ok;
  final bool usedSimDirect;
  final String? message;

  factory SimSmsResult.ok() =>
      SimSmsResult._(ok: true, usedSimDirect: true, message: null);

  factory SimSmsResult.openedComposer() => SimSmsResult._(
        ok: true,
        usedSimDirect: false,
        message: null,
      );

  factory SimSmsResult.failure(String msg) => SimSmsResult._(
        ok: false,
        usedSimDirect: false,
        message: msg,
      );
}

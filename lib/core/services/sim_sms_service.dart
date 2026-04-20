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

  static const String _defaultCountryCode = '235';
  static DateTime? _lastSendAt;
  static String? _lastFingerprint;

  /// Corps utilisable en SMS (retire le markdown le plus courant).
  static String plainBodyFromAssistantText(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
    s = s.replaceAll(RegExp(r'[*_`#]'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String normalizePhone(String raw) {
    final s = raw.trim();
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (s.startsWith('+')) return '+$digits';
    if (s.startsWith('00')) {
      final cut = digits.length > 2 ? digits.substring(2) : '';
      return cut.isEmpty ? '' : '+$cut';
    }
    // Formats locaux Tchad.
    if (digits.length == 8) return '+$_defaultCountryCode$digits';
    if (digits.length == 9 && digits.startsWith('0')) {
      return '+$_defaultCountryCode${digits.substring(1)}';
    }
    if (digits.startsWith(_defaultCountryCode) && digits.length >= 11) {
      return '+$digits';
    }
    return '+$digits';
  }

  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  static Future<SimSmsResult> send({
    required String toE164,
    required String body,
  }) async {
    final bodyTrim = body.trim();
    if (bodyTrim.isEmpty) {
      return SimSmsResult.failure('Message vide.');
    }
    final normalized = normalizePhone(toE164);
    if (!isValidPhone(normalized)) {
      return SimSmsResult.failure('Numéro invalide.');
    }
    final fp = '$normalized|$bodyTrim';
    if (_lastFingerprint == fp &&
        _lastSendAt != null &&
        DateTime.now().difference(_lastSendAt!) < const Duration(seconds: 8)) {
      return SimSmsResult.failure('Envoi ignoré: doublon détecté.');
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
    if (perm.isPermanentlyDenied) {
      return SimSmsResult.failure(
        'Permission SMS bloquée. Ouvrez les paramètres pour l’activer.',
      );
    }
    if (!perm.isGranted) {
      return SimSmsResult.failure(
        'Permission SMS refusée. Activez-la dans les paramètres de l’application.',
      );
    }

    try {
      final telephony = Telephony.instance;
      await telephony.sendSms(
        to: normalized.replaceFirst('+', ''),
        message: bodyTrim,
      );
      _lastSendAt = DateTime.now();
      _lastFingerprint = fp;
      return SimSmsResult.ok();
    } on PlatformException catch (e) {
      // Fallback robustesse: ouvrir le composeur SMS avec message pré-rempli.
      final fallback = await _openSmsComposer(
        toE164: normalized,
        body: bodyTrim,
      );
      if (fallback.ok) return fallback;
      return SimSmsResult.failure(e.message ?? 'Envoi SMS impossible.');
    } catch (e) {
      final fallback = await _openSmsComposer(
        toE164: normalized,
        body: bodyTrim,
      );
      if (fallback.ok) return fallback;
      return SimSmsResult.failure(e.toString());
    }
  }

  static Future<SimSmsResult> _sendIosComposer({
    required String toE164,
    required String body,
  }) async {
    final digits = normalizePhone(toE164).replaceAll(RegExp(r'[^\d+]'), '');
    final path = digits.startsWith('+') ? digits : '+$digits';
    return _openSmsComposer(toE164: path, body: body);
  }

  static Future<SimSmsResult> _openSmsComposer({
    required String toE164,
    required String body,
  }) async {
    final path = normalizePhone(toE164);
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

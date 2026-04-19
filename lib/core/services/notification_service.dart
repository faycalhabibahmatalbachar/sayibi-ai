import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Gestion FCM (Firebase Cloud Messaging) — aligné avec firebase_core ^3.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('FCM background: ${message.messageId}');
  }
}

/// Service singleton — token disponible dans [fcmToken] après [init].
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  String? fcmToken;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('NotificationService: permission notifications refusée');
        }
        return;
      }

      fcmToken = await messaging.getToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => fcmToken = t);

      if (kDebugMode) {
        final preview = fcmToken == null || fcmToken!.length < 12
            ? fcmToken
            : '${fcmToken!.substring(0, 12)}…';
        debugPrint('NotificationService: FCM token = $preview');
      }
    } on UnsupportedError catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: $e — utilisez Android/iOS/Web configuré.');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NotificationService: init échouée ($e)');
        debugPrint('$st');
        debugPrint(
          'Remplacez lib/firebase_options.dart via : flutterfire configure',
        );
      }
    }
  }
}

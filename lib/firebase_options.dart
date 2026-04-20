// Fichier modèle — remplacez par la sortie de : dart pub global activate flutterfire_cli && flutterfire configure
//
// Valeurs factices : l'initialisation Firebase échouera tant que vous n'aurez pas
// exécuté `flutterfire configure` avec votre projet Firebase (ChadGpt / ex-SAYIBI-AI).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme (à générer avec FlutterFire CLI).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions : ajoutez votre plateforme ou exécutez flutterfire configure.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHq3wlJv9tz4_dPcHymnCdno00-rMZkcE',
    appId: '1:541871296783:web:926ff55cbbcad385a72e7a',
    messagingSenderId: '541871296783',
    projectId: 'sayibi-ai',
    authDomain: 'sayibi-ai.firebaseapp.com',
    storageBucket: 'sayibi-ai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCMnW0VgWEwYYZzIQL8CRjKIC-xGfdXWg',
    appId: '1:541871296783:android:9b6302a292529364a72e7a',
    messagingSenderId: '541871296783',
    projectId: 'sayibi-ai',
    storageBucket: 'sayibi-ai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCimIywTqDg_iKoyzEnTsvKNKPGsf65dMI',
    appId: '1:541871296783:ios:8c65249c95c3cbd6a72e7a',
    messagingSenderId: '541871296783',
    projectId: 'sayibi-ai',
    storageBucket: 'sayibi-ai.firebasestorage.app',
    iosBundleId: 'com.sayibi.sayibiFlutter',
  );

  static const FirebaseOptions macos = ios;
}
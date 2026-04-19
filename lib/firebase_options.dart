// Fichier modèle — remplacez par la sortie de : dart pub global activate flutterfire_cli && flutterfire configure
//
// Valeurs factices : l'initialisation Firebase échouera tant que vous n'aurez pas
// exécuté `flutterfire configure` avec votre projet SAYIBI-AI.

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
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sayibi-ai-placeholder',
    authDomain: 'sayibi-ai-placeholder.firebaseapp.com',
    storageBucket: 'sayibi-ai-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sayibi-ai-placeholder',
    storageBucket: 'sayibi-ai-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'sayibi-ai-placeholder',
    storageBucket: 'sayibi-ai-placeholder.appspot.com',
    iosBundleId: 'com.sayibi.ai',
  );

  static const FirebaseOptions macos = ios;
}

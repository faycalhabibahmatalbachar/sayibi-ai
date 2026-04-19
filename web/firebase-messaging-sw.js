/**
 * Service worker minimal pour éviter un 404 (MIME text/html) sur /firebase-messaging-sw.js.
 * Pour les notifications Web Push : exécutez `flutterfire configure`, puis remplacez ce fichier
 * par la version complète (importScripts + firebase.initializeApp) alignée sur firebase_options.dart.
 * @see https://firebase.google.com/docs/cloud-messaging/js/client
 */
self.addEventListener('install', function () {
  self.skipWaiting();
});
self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

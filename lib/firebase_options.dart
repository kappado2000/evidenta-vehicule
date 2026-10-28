// File generated manually to match `flutterfire configure` output format.
// Reuses the existing Firebase project `evidenta-autovehicule` (same backend
// as the PWA at evidenta-autovehicule.web.app) — a new iOS app registration
// was added to that project, web config is copied from the PWA's index.html.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform - doar iOS și web sunt folosite în acest proiect.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCf9W9J-tzz7f1ZS0grgswv-2JrtlAsrMo',
    appId: '1:530769271612:web:c3caf7ece9265cb8311c39',
    messagingSenderId: '530769271612',
    projectId: 'evidenta-autovehicule',
    authDomain: 'evidenta-autovehicule.firebaseapp.com',
    storageBucket: 'evidenta-autovehicule.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDND2awoKx9i6Yz9ZrB9XdnDCHdVCuGZ0U',
    appId: '1:530769271612:ios:6d2c3886d7b46679311c39',
    messagingSenderId: '530769271612',
    projectId: 'evidenta-autovehicule',
    storageBucket: 'evidenta-autovehicule.firebasestorage.app',
    iosBundleId: 'com.kappado.evidentavehicule',
  );
}

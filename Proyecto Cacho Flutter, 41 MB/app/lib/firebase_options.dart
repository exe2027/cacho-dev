// ARCHIVO GENERADO AUTOMÁTICAMENTE — NO EDITAR MANUALMENTE
// Este archivo es un PLACEHOLDER temporal.
//
// Para generar el archivo real con tus claves de Firebase:
//   1. Ve a https://console.firebase.google.com y crea un proyecto
//   2. En la terminal del proyecto, corre:
//      flutterfire configure --project=TU-PROYECTO-ID
//   3. Ese comando reemplazará este archivo con las claves correctas.
//
// ADVERTENCIA: sin las claves reales, el login Google y Firestore NO funcionarán.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Reemplaza estos valores con los de tu proyecto Firebase ──────────────
  // Los encuentras en: Consola Firebase → Configuración del proyecto → Tus apps

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY_WEB',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'TU-PROYECTO-ID',
    authDomain: 'TU-PROYECTO-ID.firebaseapp.com',
    storageBucket: 'TU-PROYECTO-ID.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'TU-PROYECTO-ID',
    storageBucket: 'TU-PROYECTO-ID.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'TU-PROYECTO-ID',
    storageBucket: 'TU-PROYECTO-ID.firebasestorage.app',
    iosBundleId: 'com.example.cachoApp',
  );
}

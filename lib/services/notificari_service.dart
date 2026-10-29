import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _canalDiagnostic = MethodChannel('evidenta_auto/diagnostic');

/// Înregistrare + afișare notificări push native (APNs prin FCM).
///
/// Logica de alertă (praguri, deduplicare, programare zilnică) rămâne 100%
/// pe server (`trimiteAlerteZilnice` în functions/index.js, neschimbată) —
/// aici doar înregistrăm tokenul și afișăm ce trimite serverul.
///
/// Re-înregistrarea se face silențios la FIECARE pornire a aplicației, nu
/// doar la activarea manuală din Setări: în PWA, tokenul expira neobservat
/// pe iOS pentru că reînnoirea silențioasă avea o eroare care trecea
/// neobservată — aici orice eșec trebuie expus în UI, nu doar logat.
class NotificariService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  bool _localNotifInitializat = false;

  Future<void> _initializeazaLocalNotif() async {
    if (_localNotifInitializat) return;
    const setariIos = DarwinInitializationSettings();
    const setariAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(iOS: setariIos, android: setariAndroid),
    );
    _localNotifInitializat = true;
  }

  /// Cere permisiune (dacă nu a fost cerută deja) și salvează tokenul curent
  /// în `users/{dataOwnerUid}/fcmTokens/{token}`. Aruncă dacă permisiunea e
  /// refuzată sau tokenul nu poate fi obținut — apelantul trebuie să
  /// semnaleze eroarea în UI, nu doar să o înghită.
  Future<void> activeazaSiInregistreaza(String dataOwnerUid) async {
    final setari = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (setari.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('Notificările au fost refuzate din Setări iOS.');
    }

    await _initializeazaLocalNotif();

    // Pe iOS, `getToken()` eșuează cu „apns-token-not-set" dacă e apelat
    // înainte ca sistemul să fi livrat deja tokenul APNs către FCM - e o
    // cursă reală pe dispozitiv fizic, nu o eroare de configurare. Așteptăm
    // tokenul APNs, cu reîncercări, înainte de a cere tokenul FCM. La prima
    // pornire după o instalare proaspătă (TestFlight), înregistrarea la
    // APNs poate dura mai mult de 10s - de-aia fereastra e de 30s.
    if (!kIsWeb && Platform.isIOS) {
      // Apel explicit - pe AppDelegate-ul de tip "implicit engine", apelul
      // automat Firebase (swizzling) nu pare să pornească deloc înregistrarea
      // la APNs (nici succes, nici eroare nativă nu se declanșează).
      try {
        await _canalDiagnostic.invokeMethod('inregistreazaRemote');
      } catch (_) {
        // Canalul nu există pe web/Android - ignorăm.
      }
      var apnsToken = await _messaging.getAPNSToken();
      var incercari = 0;
      while (apnsToken == null && incercari < 30) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await _messaging.getAPNSToken();
        incercari++;
      }
      if (apnsToken == null) {
        String? eroareNativa;
        try {
          eroareNativa = await _canalDiagnostic.invokeMethod<String>(
            'ultimaEroareApns',
          );
        } catch (_) {
          // Canalul nu există pe web/Android - ignorăm, mesajul de mai jos
          // rămâne cel generic.
        }
        throw Exception(
          eroareNativa != null
              ? 'Tokenul APNs a fost refuzat de Apple: $eroareNativa'
              : 'Tokenul APNs nu a fost disponibil la timp. Încearcă din nou mai târziu.',
        );
      }
    }

    final token = await _messaging.getToken();
    if (token == null) {
      throw Exception('Nu s-a putut obține tokenul de notificare.');
    }

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'userId': user?.uid ?? '',
          'email': user?.email ?? '',
          'platform': 'mobile',
          'tip': 'fcm',
          'activ': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Afișează un mesaj primit cât aplicația e în prim-plan (iOS nu arată
  /// automat banner-ul de sistem pentru push-urile primite în foreground).
  Future<void> configureazaAfisarePrimPlan() async {
    await _initializeazaLocalNotif();
    FirebaseMessaging.onMessage.listen((RemoteMessage mesaj) async {
      final titlu = mesaj.data['title'] ?? mesaj.notification?.title ?? '';
      final corp = mesaj.data['body'] ?? mesaj.notification?.body ?? '';
      if (titlu.isEmpty && corp.isEmpty) return;
      await _localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titlu,
        corp,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentBadge: true,
            presentSound: true,
            presentList: true,
          ),
          android: AndroidNotificationDetails(
            'evidenta_auto_alerte',
            'Alerte vehicule',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}

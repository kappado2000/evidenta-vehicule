import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/garaj_service.dart';
import '../services/notificari_service.dart';

enum StareAuth { seIncarca, autentificat, neautentificat }

/// Starea globală de autentificare + rezolvarea `dataOwnerUid` (vezi
/// GarajService) — singura sursă a acestei valori în toată aplicația.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GarajService _garajService = GarajService();
  final NotificariService _notifService = NotificariService();

  StreamSubscription<User?>? _subAuth;

  StareAuth stare = StareAuth.seIncarca;
  User? user;
  String? dataOwnerUid;
  String? garajId;
  bool esteProprietar = true;
  String? eroareInregistrareNotificari;

  AuthProvider() {
    _subAuth = _authService.schimbariAuth.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? userNou) async {
    user = userNou;
    if (userNou == null) {
      dataOwnerUid = null;
      stare = StareAuth.neautentificat;
      notifyListeners();
      return;
    }

    stare = StareAuth.seIncarca;
    notifyListeners();

    try {
      final info = await _garajService.initializeaza();
      dataOwnerUid = info.dataOwnerUid;
      garajId = info.garajId;
      esteProprietar = info.esteProprietar;
      stare = StareAuth.autentificat;
      notifyListeners();

      // Re-înregistrare silențioasă la fiecare pornire — vezi comentariul
      // din NotificariService despre cauza reală a notificărilor pierdute
      // în versiunea PWA (token expirat neobservat).
      _notifService.configureazaAfisarePrimPlan();
      try {
        await _notifService.activeazaSiInregistreaza(dataOwnerUid!);
        eroareInregistrareNotificari = null;
      } catch (e) {
        eroareInregistrareNotificari = e.toString();
      }
      notifyListeners();
    } catch (e) {
      stare = StareAuth.neautentificat;
      notifyListeners();
    }
  }

  Future<void> login(String email, String parola) =>
      _authService.login(email, parola);

  Future<void> inregistreaza(String email, String parola) =>
      _authService.inregistreaza(email, parola);

  Future<void> delogare() => _authService.delogare();

  Future<void> resetareParola(String email) =>
      _authService.resetareParola(email);

  @override
  void dispose() {
    _subAuth?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../models/asigurare.dart';
import '../models/itp.dart';
import '../models/revizie.dart';
import '../models/rovinieta.dart';
import '../models/vehicul.dart';
import '../services/firestore_repo.dart';
import '../utils/date_utils.dart';

/// Praguri de alertă + ora de notificare, din `users/{dataOwnerUid}/setari/config`.
/// Valorile implicite sunt cele cerute de user pentru Evidența Auto (diferite
/// de cele din PWA/functions/index.js, care rămân neschimbate acolo).
class SetariAlerte {
  final int alertaITP;
  final int alertaRovinieta;
  final int alertaAsigurare;
  final int alertaRevizieZile;
  final int oraNotificare;

  const SetariAlerte({
    this.alertaITP = 10,
    this.alertaRovinieta = 3,
    this.alertaAsigurare = 3,
    this.alertaRevizieZile = 7,
    this.oraNotificare = 8,
  });

  factory SetariAlerte.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const SetariAlerte();
    return SetariAlerte(
      alertaITP: (data['alertaITP'] as num?)?.toInt() ?? 10,
      alertaRovinieta: (data['alertaRovinieta'] as num?)?.toInt() ?? 3,
      alertaAsigurare: (data['alertaAsigurare'] as num?)?.toInt() ?? 3,
      alertaRevizieZile: (data['alertaRevizieZile'] as num?)?.toInt() ?? 7,
      oraNotificare: (data['oraNotificare'] as num?)?.toInt() ?? 8,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'alertaITP': alertaITP,
    'alertaRovinieta': alertaRovinieta,
    'alertaAsigurare': alertaAsigurare,
    'alertaRevizieZile': alertaRevizieZile,
    'oraNotificare': oraNotificare,
  };
}

/// Agregă toate colecțiile unui `dataOwnerUid` (vehicule + itp + rovinietă +
/// asigurări + revizii + setări) și derivă alertele / costurile — aceeași
/// logică folosită în PWA, portată fidel (vezi `proceseazaAlerteUser` și
/// `calculeazaCosturi()` în functions/index.js / index.html, păstrate ca
/// referință de comportament, nu de cod).
class DateProvider extends ChangeNotifier {
  final String dataOwnerUid;

  late final FirestoreRepo<Vehicul> vehiculeRepo;
  late final FirestoreRepo<Itp> itpRepo;
  late final FirestoreRepo<Rovinieta> rovinietaRepo;
  late final FirestoreRepo<Asigurare> asigurariRepo;
  late final FirestoreRepo<Revizie> reviziiRepo;

  List<Vehicul> vehicule = [];
  List<Itp> itpuri = [];
  List<Rovinieta> rovinete = [];
  List<Asigurare> asigurari = [];
  List<Revizie> revizii = [];
  SetariAlerte setari = const SetariAlerte();
  // Chei (`Alerta.cheie`) ale alertelor închise manual de user - vezi
  // `alerte` mai jos, unde sunt excluse din listă. Cheia include data de
  // expirare curentă, deci o alertă închisă reapare automat dacă userul
  // modifică ulterior acea dată (reînnoire), fără să rămână ascunsă pentru
  // totdeauna pe acel tip+vehicul.
  Set<String> alerteInchise = {};
  bool seIncarca = true;

  final List<StreamSubscription> _subs = [];

  DateProvider({required this.dataOwnerUid}) {
    vehiculeRepo = FirestoreRepo<Vehicul>(
      dataOwnerUid: dataOwnerUid,
      colectie: 'vehicule',
      fromFirestore: Vehicul.fromFirestore,
      toFirestore: (v) => v.toFirestore(),
    );
    itpRepo = FirestoreRepo<Itp>(
      dataOwnerUid: dataOwnerUid,
      colectie: 'itp',
      fromFirestore: Itp.fromFirestore,
      toFirestore: (v) => v.toFirestore(),
    );
    rovinietaRepo = FirestoreRepo<Rovinieta>(
      dataOwnerUid: dataOwnerUid,
      colectie: 'rovinieta',
      fromFirestore: Rovinieta.fromFirestore,
      toFirestore: (v) => v.toFirestore(),
    );
    asigurariRepo = FirestoreRepo<Asigurare>(
      dataOwnerUid: dataOwnerUid,
      colectie: 'asigurari',
      fromFirestore: Asigurare.fromFirestore,
      toFirestore: (v) => v.toFirestore(),
    );
    reviziiRepo = FirestoreRepo<Revizie>(
      dataOwnerUid: dataOwnerUid,
      colectie: 'revizii',
      fromFirestore: Revizie.fromFirestore,
      toFirestore: (v) => v.toFirestore(),
    );

    _subs.add(
      vehiculeRepo.asculta().listen((v) {
        vehicule = v;
        seIncarca = false;
        notifyListeners();
      }),
    );
    _subs.add(
      itpRepo.asculta().listen((v) {
        itpuri = v;
        notifyListeners();
      }),
    );
    _subs.add(
      rovinietaRepo.asculta().listen((v) {
        rovinete = v;
        notifyListeners();
      }),
    );
    _subs.add(
      asigurariRepo.asculta().listen((v) {
        asigurari = v;
        notifyListeners();
      }),
    );
    _subs.add(
      reviziiRepo.asculta().listen((v) {
        revizii = v;
        notifyListeners();
      }),
    );
    _subs.add(
      FirebaseFirestore.instance
          .collection('users')
          .doc(dataOwnerUid)
          .collection('setari')
          .doc('config')
          .snapshots()
          .listen((snap) {
            setari = SetariAlerte.fromFirestore(snap.data());
            notifyListeners();
          }),
    );
    _subs.add(
      FirebaseFirestore.instance
          .collection('users')
          .doc(dataOwnerUid)
          .collection('alerteInchise')
          .snapshots()
          .listen((snap) {
            alerteInchise = snap.docs.map((d) => d.id).toSet();
            notifyListeners();
          }),
    );
  }

  /// Închide manual o alertă (nu șterge înregistrarea) - reapare automat
  /// dacă data ei de expirare se schimbă ulterior, vezi `Alerta.cheie`.
  Future<void> inchideAlerta(Alerta a) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('alerteInchise')
        .doc(a.cheie)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  /// Reafișează toate alertele închise manual (vezi `inchideAlerta`).
  Future<void> deschideToateAlertele() async {
    final colectie = FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('alerteInchise');
    final snap = await colectie.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> salveazaSetari(SetariAlerte noi) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('setari')
        .doc('config')
        .set(noi.toFirestore(), SetOptions(merge: true));
  }

  Vehicul? vehiculDupaId(String id) {
    for (final v in vehicule) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Cea mai recentă înregistrare per vehicul (asigurările se țin separat
  /// per `tip`, ca RCA și CASCO să alerteze independent — la fel ca server).
  List<T> _ultimeleInregistrari<T>(
    List<T> toate,
    String Function(T) cheie,
    DateTime? Function(T) timestamp,
  ) {
    final ultimele = <String, T>{};
    for (final item in toate) {
      final existent = ultimele[cheie(item)];
      if (existent == null) {
        ultimele[cheie(item)] = item;
        continue;
      }
      final tsNou = timestamp(item);
      final tsExistent = timestamp(existent);
      if (tsNou != null && (tsExistent == null || tsNou.isAfter(tsExistent))) {
        ultimele[cheie(item)] = item;
      }
    }
    return ultimele.values.toList();
  }

  List<Alerta> get alerte {
    final rezultat = <Alerta>[];

    for (final itp in _ultimeleInregistrari(
      itpuri,
      (i) => i.vehiculId,
      (i) => i.timestamp,
    )) {
      final dif = zilePanaLa(itp.dataExpirare);
      if (dif == null || dif > setari.alertaITP || dif < -365) continue;
      final v = vehiculDupaId(itp.vehiculId);
      rezultat.add(
        Alerta(
          tip: TipAlerta.itp,
          vehiculId: itp.vehiculId,
          numarVehicul: v?.nr ?? '',
          titlu: 'ITP${v != null ? ' - ${v.nr}' : ''}',
          mesaj: dif < 0
              ? 'ITP expirat de ${-dif} zile'
              : 'ITP expiră în $dif zile',
          zileRamase: dif,
          itemId: itp.id,
          dataExpirare: itp.dataExpirare,
        ),
      );
    }

    for (final rov in _ultimeleInregistrari(
      rovinete,
      (r) => r.vehiculId,
      (r) => r.timestamp,
    )) {
      final dif = zilePanaLa(rov.dataExpirare);
      if (dif == null || dif > setari.alertaRovinieta || dif < -365) continue;
      final v = vehiculDupaId(rov.vehiculId);
      rezultat.add(
        Alerta(
          tip: TipAlerta.rovinieta,
          vehiculId: rov.vehiculId,
          numarVehicul: v?.nr ?? '',
          titlu: 'Rovinietă${v != null ? ' - ${v.nr}' : ''}',
          mesaj: dif < 0
              ? 'Rovinietă expirată de ${-dif} zile'
              : 'Rovinietă expiră în $dif zile',
          zileRamase: dif,
          itemId: rov.id,
          dataExpirare: rov.dataExpirare,
        ),
      );
    }

    for (final asig in _ultimeleInregistrari(
      asigurari,
      (a) => '${a.vehiculId}_${a.tip}',
      (a) => a.timestamp,
    )) {
      final dif = zilePanaLa(asig.dataExpirare);
      if (dif == null || dif > setari.alertaAsigurare || dif < -365) continue;
      final v = vehiculDupaId(asig.vehiculId);
      rezultat.add(
        Alerta(
          tip: TipAlerta.asigurare,
          vehiculId: asig.vehiculId,
          numarVehicul: v?.nr ?? '',
          titlu: '${asig.tip}${v != null ? ' - ${v.nr}' : ''}',
          mesaj: dif < 0
              ? '${asig.tip} expirată de ${-dif} zile'
              : '${asig.tip} expiră în $dif zile',
          zileRamase: dif,
          itemId: asig.id,
          dataExpirare: asig.dataExpirare,
        ),
      );
    }

    for (final rev in _ultimeleInregistrari(
      revizii,
      (r) => r.vehiculId,
      (r) => r.timestamp,
    )) {
      final dif = zilePanaLa(rev.proximData);
      if (dif == null || dif > setari.alertaRevizieZile || dif < -365) {
        continue;
      }
      final v = vehiculDupaId(rev.vehiculId);
      rezultat.add(
        Alerta(
          tip: TipAlerta.revizie,
          vehiculId: rev.vehiculId,
          numarVehicul: v?.nr ?? '',
          titlu: 'Revizie${v != null ? ' - ${v.nr}' : ''}',
          mesaj: dif < 0
              ? 'Revizie restantă de ${-dif} zile'
              : 'Revizie recomandată în $dif zile',
          zileRamase: dif,
          itemId: rev.id,
          dataExpirare: rev.proximData,
        ),
      );
    }

    rezultat.removeWhere((a) => alerteInchise.contains(a.cheie));
    rezultat.sort((a, b) => a.zileRamase.compareTo(b.zileRamase));
    return rezultat;
  }

  /// Agregare costuri pe anul curent, pe categorie — fără nicio colecție
  /// nouă, exact ca `calculeazaCosturi()` din PWA.
  Map<String, num> get costuriPeCategorieAnCurent {
    final anCurent = DateTime.now().year;
    num totalItp = 0, totalRov = 0, totalAsig = 0, totalRevizii = 0;

    for (final i in itpuri) {
      if (_anDin(i.dataEfectuare) == anCurent) totalItp += i.cost;
    }
    for (final r in rovinete) {
      if (_anDin(r.dataInceput) == anCurent) totalRov += r.cost;
    }
    for (final a in asigurari) {
      if (_anDin(a.dataInceput) == anCurent) totalAsig += a.cost;
    }
    for (final r in revizii) {
      if (_anDin(r.data) == anCurent) totalRevizii += r.costTotal;
    }

    return {
      'ITP': totalItp,
      'Rovinietă': totalRov,
      'Asigurări': totalAsig,
      'Revizii': totalRevizii,
    };
  }

  int? _anDin(String dataIso) => DateTime.tryParse(dataIso)?.year;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

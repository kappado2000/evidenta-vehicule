import 'package:cloud_firestore/cloud_firestore.dart';

import 'fisier_atasat.dart';

class Revizie {
  final String id;
  final String vehiculId;
  final String tip;
  final String data;
  final int? km;
  final String service;
  final String locatie;
  final String piese;
  final num costManopera;
  final num costPiese;
  final num costTotal;
  final int? proximKm;
  final String proximData;
  final String observatii;
  final List<FisierAtasat> documente;
  final DateTime? timestamp;

  const Revizie({
    required this.id,
    required this.vehiculId,
    this.tip = '',
    this.data = '',
    this.km,
    this.service = '',
    this.locatie = '',
    this.piese = '',
    this.costManopera = 0,
    this.costPiese = 0,
    this.costTotal = 0,
    this.proximKm,
    this.proximData = '',
    this.observatii = '',
    this.documente = const [],
    this.timestamp,
  });

  factory Revizie.fromFirestore(String id, Map<String, dynamic> data) {
    return Revizie(
      id: id,
      vehiculId: data['vehiculId'] as String? ?? '',
      tip: data['tip'] as String? ?? '',
      data: data['data'] as String? ?? '',
      km: (data['km'] as num?)?.toInt(),
      service: data['service'] as String? ?? '',
      locatie: data['locatie'] as String? ?? '',
      piese: data['piese'] as String? ?? '',
      costManopera: data['costManopera'] as num? ?? 0,
      costPiese: data['costPiese'] as num? ?? 0,
      costTotal: data['costTotal'] as num? ?? 0,
      proximKm: (data['proximKm'] as num?)?.toInt(),
      proximData: data['proximData'] as String? ?? '',
      observatii: data['observatii'] as String? ?? '',
      documente: FisierAtasat.listaFromDynamic(data['documente']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vehiculId': vehiculId,
      'tip': tip,
      'data': data,
      'km': km,
      'service': service,
      'locatie': locatie,
      'piese': piese,
      'costManopera': costManopera,
      'costPiese': costPiese,
      'costTotal': costTotal,
      'proximKm': proximKm,
      'proximData': proximData,
      'observatii': observatii,
      'documente': FisierAtasat.listaToMap(documente),
    };
  }
}

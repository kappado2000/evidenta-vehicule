import 'package:cloud_firestore/cloud_firestore.dart';

import 'fisier_atasat.dart';

class Itp {
  final String id;
  final String vehiculId;
  final String dataEfectuare;
  final String dataExpirare;
  final num cost;
  final List<FisierAtasat> documente;
  final DateTime? timestamp;

  const Itp({
    required this.id,
    required this.vehiculId,
    this.dataEfectuare = '',
    this.dataExpirare = '',
    this.cost = 0,
    this.documente = const [],
    this.timestamp,
  });

  factory Itp.fromFirestore(String id, Map<String, dynamic> data) {
    return Itp(
      id: id,
      vehiculId: data['vehiculId'] as String? ?? '',
      dataEfectuare: data['dataEfectuare'] as String? ?? '',
      dataExpirare: data['dataExpirare'] as String? ?? '',
      cost: data['cost'] as num? ?? 0,
      documente: FisierAtasat.listaFromDynamic(data['documente']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vehiculId': vehiculId,
      'dataEfectuare': dataEfectuare,
      'dataExpirare': dataExpirare,
      'cost': cost,
      'documente': FisierAtasat.listaToMap(documente),
    };
  }
}

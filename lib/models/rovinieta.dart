import 'package:cloud_firestore/cloud_firestore.dart';

import 'fisier_atasat.dart';

const List<String> tipuriRovinieta = ['anuala', '7zile', '30zile', '90zile'];

class Rovinieta {
  final String id;
  final String vehiculId;
  final String tip;
  final String dataInceput;
  final String dataExpirare;
  final num cost;
  final List<FisierAtasat> documente;
  final DateTime? timestamp;

  const Rovinieta({
    required this.id,
    required this.vehiculId,
    this.tip = 'anuala',
    this.dataInceput = '',
    this.dataExpirare = '',
    this.cost = 0,
    this.documente = const [],
    this.timestamp,
  });

  factory Rovinieta.fromFirestore(String id, Map<String, dynamic> data) {
    return Rovinieta(
      id: id,
      vehiculId: data['vehiculId'] as String? ?? '',
      tip: data['tip'] as String? ?? 'anuala',
      dataInceput: data['dataInceput'] as String? ?? '',
      dataExpirare: data['dataExpirare'] as String? ?? '',
      cost: data['cost'] as num? ?? 0,
      documente: FisierAtasat.listaFromDynamic(data['documente']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vehiculId': vehiculId,
      'tip': tip,
      'dataInceput': dataInceput,
      'dataExpirare': dataExpirare,
      'cost': cost,
      'documente': FisierAtasat.listaToMap(documente),
    };
  }
}

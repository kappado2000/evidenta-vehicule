import 'package:cloud_firestore/cloud_firestore.dart';

import 'fisier_atasat.dart';

const List<String> tipuriAsigurare = ['RCA', 'CASCO', 'Altă asigurare'];

class Asigurare {
  final String id;
  final String vehiculId;
  final String tip;
  final String furnizor;
  final String polita;
  final String dataInceput;
  final String dataExpirare;
  final num cost;
  final String observatii;
  final FisierAtasat? documentPolita;
  final DateTime? timestamp;

  const Asigurare({
    required this.id,
    required this.vehiculId,
    this.tip = 'RCA',
    this.furnizor = '',
    this.polita = '',
    this.dataInceput = '',
    this.dataExpirare = '',
    this.cost = 0,
    this.observatii = '',
    this.documentPolita,
    this.timestamp,
  });

  factory Asigurare.fromFirestore(String id, Map<String, dynamic> data) {
    final docRaw = data['documentPolita'];
    return Asigurare(
      id: id,
      vehiculId: data['vehiculId'] as String? ?? '',
      tip: data['tip'] as String? ?? 'RCA',
      furnizor: data['furnizor'] as String? ?? '',
      polita: data['polita'] as String? ?? '',
      dataInceput: data['dataInceput'] as String? ?? '',
      dataExpirare: data['dataExpirare'] as String? ?? '',
      cost: data['cost'] as num? ?? 0,
      observatii: data['observatii'] as String? ?? '',
      documentPolita: docRaw is Map
          ? FisierAtasat.fromMap(Map<String, dynamic>.from(docRaw))
          : null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vehiculId': vehiculId,
      'tip': tip,
      'furnizor': furnizor,
      'polita': polita,
      'dataInceput': dataInceput,
      'dataExpirare': dataExpirare,
      'cost': cost,
      'observatii': observatii,
      'documentPolita': documentPolita?.toMap(),
    };
  }
}

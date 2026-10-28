import 'fisier_atasat.dart';

class Vehicul {
  final String id;
  final String nr;
  final String marca;
  final String model;
  final int? an;
  final int? km;
  final String vin;
  final String combustibil;
  final String culoare;
  final String observatii;
  final num? capacitateCilindrica;
  final num? putereCP;
  final String anvelope;
  final String fotoUrl;
  final String fotoPath;
  final List<FisierAtasat> talon;
  final List<FisierAtasat> carteIdentitate;

  const Vehicul({
    required this.id,
    required this.nr,
    this.marca = '',
    this.model = '',
    this.an,
    this.km,
    this.vin = '',
    this.combustibil = '',
    this.culoare = '',
    this.observatii = '',
    this.capacitateCilindrica,
    this.putereCP,
    this.anvelope = '',
    this.fotoUrl = '',
    this.fotoPath = '',
    this.talon = const [],
    this.carteIdentitate = const [],
  });

  // Citire tolerantă la alias-urile vechi folosite de PWA pentru numărul de
  // înmatriculare (nr / nrInmatriculare / numar) — doar `nr` se mai scrie azi.
  factory Vehicul.fromFirestore(String id, Map<String, dynamic> data) {
    return Vehicul(
      id: id,
      nr:
          (data['nr'] ?? data['nrInmatriculare'] ?? data['numar'] ?? '')
              as String,
      marca: data['marca'] as String? ?? '',
      model: data['model'] as String? ?? '',
      an: (data['an'] as num?)?.toInt(),
      km: (data['km'] as num?)?.toInt(),
      vin: data['vin'] as String? ?? '',
      combustibil: data['combustibil'] as String? ?? '',
      culoare: data['culoare'] as String? ?? '',
      observatii: data['observatii'] as String? ?? '',
      capacitateCilindrica: data['capacitateCilindrica'] as num?,
      putereCP: data['putereCP'] as num?,
      anvelope: data['anvelope'] as String? ?? '',
      fotoUrl: data['fotoUrl'] as String? ?? '',
      fotoPath: data['fotoPath'] as String? ?? '',
      talon: FisierAtasat.listaFromDynamic(data['talon']),
      carteIdentitate: FisierAtasat.listaFromDynamic(data['carteIdentitate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nr': nr.toUpperCase(),
      'marca': marca,
      'model': model,
      'an': an,
      'km': km,
      'vin': vin,
      'combustibil': combustibil,
      'culoare': culoare,
      'observatii': observatii,
      'capacitateCilindrica': capacitateCilindrica,
      'putereCP': putereCP,
      'anvelope': anvelope,
      'fotoUrl': fotoUrl,
      'fotoPath': fotoPath,
      'talon': FisierAtasat.listaToMap(talon),
      'carteIdentitate': FisierAtasat.listaToMap(carteIdentitate),
    };
  }

  Vehicul copyWith({
    String? nr,
    String? marca,
    String? model,
    int? an,
    int? km,
    String? vin,
    String? combustibil,
    String? culoare,
    String? observatii,
    num? capacitateCilindrica,
    num? putereCP,
    String? anvelope,
    String? fotoUrl,
    String? fotoPath,
    List<FisierAtasat>? talon,
    List<FisierAtasat>? carteIdentitate,
  }) {
    return Vehicul(
      id: id,
      nr: nr ?? this.nr,
      marca: marca ?? this.marca,
      model: model ?? this.model,
      an: an ?? this.an,
      km: km ?? this.km,
      vin: vin ?? this.vin,
      combustibil: combustibil ?? this.combustibil,
      culoare: culoare ?? this.culoare,
      observatii: observatii ?? this.observatii,
      capacitateCilindrica: capacitateCilindrica ?? this.capacitateCilindrica,
      putereCP: putereCP ?? this.putereCP,
      anvelope: anvelope ?? this.anvelope,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoPath: fotoPath ?? this.fotoPath,
      talon: talon ?? this.talon,
      carteIdentitate: carteIdentitate ?? this.carteIdentitate,
    );
  }

  String get numeAfisat => '$marca $model'.trim();
}

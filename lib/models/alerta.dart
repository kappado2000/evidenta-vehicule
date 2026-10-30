enum TipAlerta { itp, rovinieta, asigurare, revizie }

class Alerta {
  final TipAlerta tip;
  final String vehiculId;
  final String numarVehicul;
  final String titlu;
  final String mesaj;
  final int zileRamase;
  final String itemId;
  final String dataExpirare;

  const Alerta({
    required this.tip,
    required this.vehiculId,
    required this.numarVehicul,
    required this.titlu,
    required this.mesaj,
    required this.zileRamase,
    required this.itemId,
    required this.dataExpirare,
  });

  bool get expirat => zileRamase < 0;

  /// Identifică unic „situația" alertată (înregistrarea + data ei de
  /// expirare curentă) - folosit la închiderea manuală a unei alerte, ca să
  /// reapară automat dacă userul modifică ulterior data (ex. reînnoire),
  /// în loc să rămână ascunsă definitiv pentru acel tip+vehicul.
  String get cheie => '${tip.name}_${itemId}_$dataExpirare';
}

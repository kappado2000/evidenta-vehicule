enum TipAlerta { itp, rovinieta, asigurare, revizie }

class Alerta {
  final TipAlerta tip;
  final String vehiculId;
  final String numarVehicul;
  final String titlu;
  final String mesaj;
  final int zileRamase;

  const Alerta({
    required this.tip,
    required this.vehiculId,
    required this.numarVehicul,
    required this.titlu,
    required this.mesaj,
    required this.zileRamase,
  });

  bool get expirat => zileRamase < 0;
}

/// Echivalentul `calcDif()` din Cloud Function: numărul de zile de la azi
/// (normalizat la miezul nopții) până la data dată, ca string ISO `yyyy-MM-dd`.
/// Negativ dacă data a trecut deja.
int? zilePanaLa(String dataIso) {
  if (dataIso.isEmpty) return null;
  final data = DateTime.tryParse(dataIso);
  if (data == null) return null;
  final azi = DateTime.now();
  final aziMiezNoapte = DateTime(azi.year, azi.month, azi.day);
  final dataMiezNoapte = DateTime(data.year, data.month, data.day);
  return dataMiezNoapte.difference(aziMiezNoapte).inDays;
}

String formateazaDataRo(String dataIso) {
  final data = DateTime.tryParse(dataIso);
  if (data == null) return dataIso;
  return '${data.day.toString().padLeft(2, '0')}.'
      '${data.month.toString().padLeft(2, '0')}.'
      '${data.year}';
}

String azIso() {
  final azi = DateTime.now();
  return '${azi.year.toString().padLeft(4, '0')}-'
      '${azi.month.toString().padLeft(2, '0')}-'
      '${azi.day.toString().padLeft(2, '0')}';
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Calculul automat al datei de expirare (ITP/Rovinietă/Asigurare/Revizie) —
/// userul poate oricând suprascrie manual rezultatul.
String? adaugaZileIso(String dataIso, int zile) {
  final data = DateTime.tryParse(dataIso);
  if (data == null) return null;
  return _iso(data.add(Duration(days: zile)));
}

/// Adaugă N ani, păstrând ziua/luna (31 feb -> martie, gestionat de
/// [DateTime] automat).
String? adaugaAniIso(String dataIso, int ani) {
  final data = DateTime.tryParse(dataIso);
  if (data == null) return null;
  return _iso(DateTime(data.year + ani, data.month, data.day));
}

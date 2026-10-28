import 'package:flutter_test/flutter_test.dart';
import 'package:evidenta_vehicule/utils/date_utils.dart';

void main() {
  group('zilePanaLa', () {
    test('returnează null pentru string gol', () {
      expect(zilePanaLa(''), isNull);
    });

    test('returnează 0 pentru data de azi', () {
      expect(zilePanaLa(azIso()), 0);
    });

    test('returnează pozitiv pentru o dată viitoare', () {
      final maine = DateTime.now().add(const Duration(days: 5));
      final iso =
          '${maine.year.toString().padLeft(4, '0')}-${maine.month.toString().padLeft(2, '0')}-${maine.day.toString().padLeft(2, '0')}';
      expect(zilePanaLa(iso), 5);
    });

    test('returnează negativ pentru o dată trecută', () {
      final trecut = DateTime.now().subtract(const Duration(days: 3));
      final iso =
          '${trecut.year.toString().padLeft(4, '0')}-${trecut.month.toString().padLeft(2, '0')}-${trecut.day.toString().padLeft(2, '0')}';
      expect(zilePanaLa(iso), -3);
    });
  });

  group('formateazaDataRo', () {
    test('formatează yyyy-MM-dd în dd.MM.yyyy', () {
      expect(formateazaDataRo('2026-10-28'), '28.10.2026');
    });

    test('returnează string-ul original dacă nu e o dată validă', () {
      expect(formateazaDataRo('nu-e-data'), 'nu-e-data');
    });
  });
}

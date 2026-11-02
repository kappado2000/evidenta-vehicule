import 'package:evidenta_vehicule/models/alerta.dart';
import 'package:evidenta_vehicule/models/asigurare.dart';
import 'package:evidenta_vehicule/models/itp.dart';
import 'package:evidenta_vehicule/models/revizie.dart';
import 'package:evidenta_vehicule/models/rovinieta.dart';
import 'package:evidenta_vehicule/models/vehicul.dart';
import 'package:evidenta_vehicule/providers/date_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Data ISO (yyyy-MM-dd) la [zile] distanță de azi.
String peste(int zile) {
  final d = DateTime.now().add(Duration(days: zile));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

const vehicul = Vehicul(id: 'v1', nr: 'IS 01 ABC');

List<Alerta> alerte({
  List<Itp> itpuri = const [],
  List<Rovinieta> rovinete = const [],
  List<Asigurare> asigurari = const [],
  List<Revizie> revizii = const [],
  SetariAlerte setari = const SetariAlerte(),
  Set<String> alerteInchise = const {},
}) => calculeazaAlerte(
  vehicule: const [vehicul],
  itpuri: itpuri,
  rovinete: rovinete,
  asigurari: asigurari,
  revizii: revizii,
  setari: setari,
  alerteInchise: alerteInchise,
);

void main() {
  group('calculeazaAlerte', () {
    test('ITP în prag (implicit 10 zile) dă alertă cu numărul vehiculului', () {
      final a = alerte(
        itpuri: [Itp(id: 'i1', vehiculId: 'v1', dataExpirare: peste(10))],
      );
      expect(a, hasLength(1));
      expect(a.single.tip, TipAlerta.itp);
      expect(a.single.titlu, 'ITP - IS 01 ABC');
      expect(a.single.mesaj, 'ITP expiră în 10 zile');
      expect(a.single.expirat, isFalse);
    });

    test('peste prag nu dă alertă; pragul vine din setări', () {
      final itp = [Itp(id: 'i1', vehiculId: 'v1', dataExpirare: peste(11))];
      expect(alerte(itpuri: itp), isEmpty);
      expect(
        alerte(itpuri: itp, setari: const SetariAlerte(alertaITP: 30)),
        hasLength(1),
      );
    });

    test('expirat: mesaj „expirat de N zile”, dar nu mai vechi de un an', () {
      final a = alerte(
        rovinete: [
          Rovinieta(id: 'r1', vehiculId: 'v1', dataExpirare: peste(-4)),
        ],
      );
      expect(a.single.mesaj, 'Rovinietă expirată de 4 zile');
      expect(a.single.expirat, isTrue);

      expect(
        alerte(
          rovinete: [
            Rovinieta(id: 'r1', vehiculId: 'v1', dataExpirare: peste(-366)),
          ],
        ),
        isEmpty,
      );
    });

    test('contează doar cea mai recentă înregistrare a vehiculului', () {
      final a = alerte(
        itpuri: [
          Itp(
            id: 'vechi',
            vehiculId: 'v1',
            dataExpirare: peste(-2),
            timestamp: DateTime(2025),
          ),
          Itp(
            id: 'nou',
            vehiculId: 'v1',
            dataExpirare: peste(365),
            timestamp: DateTime(2026),
          ),
        ],
      );
      expect(a, isEmpty, reason: 'ITP-ul reînnoit acoperă alerta celui vechi');
    });

    test('RCA și CASCO alertează separat pentru același vehicul', () {
      final a = alerte(
        asigurari: [
          Asigurare(
            id: 'a1',
            vehiculId: 'v1',
            tip: 'RCA',
            dataExpirare: peste(1),
          ),
          Asigurare(
            id: 'a2',
            vehiculId: 'v1',
            tip: 'CASCO',
            dataExpirare: peste(2),
          ),
        ],
      );
      expect(a.map((x) => x.titlu), ['RCA - IS 01 ABC', 'CASCO - IS 01 ABC']);
    });

    test('revizia folosește data următoarei revizii', () {
      final a = alerte(
        revizii: [
          Revizie(
            id: 'rv',
            vehiculId: 'v1',
            data: peste(-300),
            proximData: peste(-1),
          ),
        ],
      );
      expect(a.single.mesaj, 'Revizie restantă de 1 zi');
      expect(a.single.dataExpirare, peste(-1));
    });

    test('alerta închisă dispare, dar reapare la o dată de expirare nouă', () {
      final itp = Itp(id: 'i1', vehiculId: 'v1', dataExpirare: peste(5));
      final cheie = alerte(itpuri: [itp]).single.cheie;

      expect(alerte(itpuri: [itp], alerteInchise: {cheie}), isEmpty);

      final reinnoit = Itp(id: 'i1', vehiculId: 'v1', dataExpirare: peste(6));
      expect(alerte(itpuri: [reinnoit], alerteInchise: {cheie}), hasLength(1));
    });

    test('ordonate după urgență, expiratele primele', () {
      final a = alerte(
        itpuri: [Itp(id: 'i', vehiculId: 'v1', dataExpirare: peste(8))],
        rovinete: [
          Rovinieta(id: 'r', vehiculId: 'v1', dataExpirare: peste(-3)),
        ],
        asigurari: [
          Asigurare(id: 'a', vehiculId: 'v1', dataExpirare: peste(2)),
        ],
      );
      expect(a.map((x) => x.zileRamase), [-3, 2, 8]);
    });

    test('dată lipsă sau invalidă nu dă alertă', () {
      expect(
        alerte(
          itpuri: [
            const Itp(id: 'gol', vehiculId: 'v1'),
            const Itp(id: 'rau', vehiculId: 'v1', dataExpirare: 'mâine'),
          ],
        ),
        isEmpty,
      );
    });
  });

  test('costuriPeCategorie adună doar anul cerut, pe categorii', () {
    final c = costuriPeCategorie(
      an: 2026,
      itpuri: const [
        Itp(id: 'a', vehiculId: 'v1', dataEfectuare: '2026-03-01', cost: 150),
        Itp(id: 'b', vehiculId: 'v1', dataEfectuare: '2025-03-01', cost: 999),
      ],
      rovinete: const [
        Rovinieta(
          id: 'r',
          vehiculId: 'v1',
          dataInceput: '2026-01-10',
          cost: 28,
        ),
      ],
      asigurari: const [
        Asigurare(
          id: 's',
          vehiculId: 'v1',
          dataInceput: '2026-05-05',
          cost: 1200,
        ),
        Asigurare(id: 't', vehiculId: 'v1', dataInceput: '', cost: 50),
      ],
      revizii: const [
        Revizie(id: 'v', vehiculId: 'v1', data: '2026-07-07', costTotal: 830.5),
      ],
    );
    expect(c, {
      'ITP': 150,
      'Rovinietă': 28,
      'Asigurări': 1200,
      'Revizii': 830.5,
    });
  });
}

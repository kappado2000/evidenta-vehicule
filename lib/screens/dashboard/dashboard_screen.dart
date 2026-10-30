import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';
import '../asigurari/asigurare_form_screen.dart';
import '../itp/itp_form_screen.dart';
import '../revizii/revizie_form_screen.dart';
import '../rovinieta/rovinieta_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  IconData _iconaPentru(TipAlerta tip) {
    switch (tip) {
      case TipAlerta.itp:
        return Icons.fact_check_outlined;
      case TipAlerta.rovinieta:
        return Icons.toll_outlined;
      case TipAlerta.asigurare:
        return Icons.shield_outlined;
      case TipAlerta.revizie:
        return Icons.build_outlined;
    }
  }

  Widget _randDetaliu(String eticheta, String valoare) {
    if (valoare.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              eticheta,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(child: Text(valoare)),
        ],
      ),
    );
  }

  T? _dupaId<T>(List<T> lista, String id, String Function(T) idDe) {
    for (final item in lista) {
      if (idDe(item) == id) return item;
    }
    return null;
  }

  Future<bool> _confirmaStergere(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ștergi înregistrarea?'),
        content: const Text('Nu mai poate fi recuperată.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    return confirma ?? false;
  }

  /// Caută înregistrarea completă din spatele alertei (ITP/rovinietă/
  /// asigurare/revizie), construiește detaliile, editarea și ștergerea ei -
  /// toate 4 tipurile au același tipar, doar câmpurile afișate diferă.
  Future<void> _deschideDetaliiAlerta(
    BuildContext context,
    DateProvider date,
    Alerta a,
  ) async {
    Widget continut;
    VoidCallback onEditeaza;
    Future<void> Function() onSterge;

    switch (a.tip) {
      case TipAlerta.itp:
        final itp = _dupaId(date.itpuri, a.itemId, (i) => i.id);
        if (itp == null) return;
        continut = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _randDetaliu('Vehicul', a.numarVehicul),
            _randDetaliu('Data efectuare', formateazaDataRo(itp.dataEfectuare)),
            _randDetaliu('Data expirare', formateazaDataRo(itp.dataExpirare)),
            if (itp.cost > 0) _randDetaliu('Cost', '${itp.cost} lei'),
          ],
        );
        onEditeaza = () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItpFormScreen(vehiculId: a.vehiculId, itp: itp),
          ),
        );
        onSterge = () => date.itpRepo.sterge(itp.id);
        break;

      case TipAlerta.rovinieta:
        final rov = _dupaId(date.rovinete, a.itemId, (r) => r.id);
        if (rov == null) return;
        continut = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _randDetaliu('Vehicul', a.numarVehicul),
            _randDetaliu('Tip', rov.tip),
            _randDetaliu('Data început', formateazaDataRo(rov.dataInceput)),
            _randDetaliu('Data expirare', formateazaDataRo(rov.dataExpirare)),
            if (rov.cost > 0) _randDetaliu('Cost', '${rov.cost} lei'),
          ],
        );
        onEditeaza = () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                RovinietaFormScreen(vehiculId: a.vehiculId, rovinieta: rov),
          ),
        );
        onSterge = () => date.rovinietaRepo.sterge(rov.id);
        break;

      case TipAlerta.asigurare:
        final asig = _dupaId(date.asigurari, a.itemId, (x) => x.id);
        if (asig == null) return;
        continut = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _randDetaliu('Vehicul', a.numarVehicul),
            _randDetaliu('Tip', asig.tip),
            _randDetaliu('Furnizor', asig.furnizor),
            _randDetaliu('Poliță', asig.polita),
            _randDetaliu('Data început', formateazaDataRo(asig.dataInceput)),
            _randDetaliu('Data expirare', formateazaDataRo(asig.dataExpirare)),
            if (asig.cost > 0) _randDetaliu('Cost', '${asig.cost} lei'),
            _randDetaliu('Observații', asig.observatii),
          ],
        );
        onEditeaza = () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AsigurareFormScreen(vehiculId: a.vehiculId, asigurare: asig),
          ),
        );
        onSterge = () => date.asigurariRepo.sterge(asig.id);
        break;

      case TipAlerta.revizie:
        final rev = _dupaId(date.revizii, a.itemId, (r) => r.id);
        if (rev == null) return;
        continut = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _randDetaliu('Vehicul', a.numarVehicul),
            _randDetaliu('Tip', rev.tip),
            _randDetaliu('Data efectuare', formateazaDataRo(rev.data)),
            if (rev.km != null) _randDetaliu('Km', '${rev.km}'),
            _randDetaliu('Service', rev.service),
            _randDetaliu('Locație', rev.locatie),
            if (rev.costTotal > 0)
              _randDetaliu('Cost total', '${rev.costTotal} lei'),
            _randDetaliu(
              'Următoarea revizie',
              formateazaDataRo(rev.proximData),
            ),
            if (rev.proximKm != null)
              _randDetaliu('Km următoarea revizie', '${rev.proximKm}'),
            _randDetaliu('Observații', rev.observatii),
          ],
        );
        onEditeaza = () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                RevizieFormScreen(vehiculId: a.vehiculId, revizie: rev),
          ),
        );
        onSterge = () => date.reviziiRepo.sterge(rev.id);
        break;
    }

    if (!context.mounted) return;
    final actiune = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a.titlu),
        content: SingleChildScrollView(child: continut),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'inchide_alerta'),
            child: const Text('Nu mai arăta alerta'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'editeaza'),
                child: const Text('Editează'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'sterge'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Șterge'),
              ),
            ],
          ),
        ],
      ),
    );

    if (actiune == 'editeaza') {
      onEditeaza();
    } else if (actiune == 'sterge') {
      if (!context.mounted) return;
      final confirma = await _confirmaStergere(context);
      if (confirma) await onSterge();
    } else if (actiune == 'inchide_alerta') {
      await date.inchideAlerta(a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = context.watch<DateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alerte')),
      body: date.seIncarca
          ? const Center(child: CircularProgressIndicator())
          : date.alerte.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nicio alertă activă. Toate documentele sunt în termen.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              // Padding jos generos - bara de navigare e plutitoare (peste
              // conținut, Scaffold.extendBody), altfel ultimele rânduri
              // rămân ascunse sub ea.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: date.alerte.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = date.alerte[i];
                final culoare = a.expirat
                    ? Colors.red.shade700
                    : a.zileRamase <= 7
                    ? Colors.orange.shade800
                    : Colors.amber.shade800;
                return Dismissible(
                  key: ValueKey(a.cheie),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.visibility_off_outlined,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => date.inchideAlerta(a),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: culoare.withValues(alpha: 0.4)),
                    ),
                    color: culoare.withValues(alpha: 0.08),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 5, color: culoare),
                          Expanded(
                            child: ListTile(
                              onTap: () =>
                                  _deschideDetaliiAlerta(context, date, a),
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: culoare.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Icon(
                                      _iconaPentru(a.tip),
                                      color: culoare,
                                    ),
                                  ),
                                  if (a.expirat || a.zileRamase <= 7)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: culoare,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.priority_high,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                a.titlu,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(a.mesaj),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: culoare,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  a.expirat ? 'EXPIRAT' : '${a.zileRamase}z',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

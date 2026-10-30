import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicul.dart';
import '../../providers/date_provider.dart';
import 'vehicul_detaliu_screen.dart';
import 'vehicul_form_screen.dart';

class ListaVehiculeScreen extends StatelessWidget {
  const ListaVehiculeScreen({super.key});

  /// Culoarea de alertă (roșu dacă există ceva expirat, portocaliu dacă
  /// există doar alerte încă neexpirate) pentru vehiculul `vehiculId`, sau
  /// `null` dacă nu are nicio alertă activă - aceleași alerte ca pe pagina
  /// „Alerte" (`DateProvider.alerte`), doar grupate per vehicul.
  Color? _culoareAlerta(DateProvider date, String vehiculId) {
    var areExpirat = false;
    var areAlerta = false;
    for (final a in date.alerte) {
      if (a.vehiculId != vehiculId) continue;
      areAlerta = true;
      if (a.expirat) areExpirat = true;
    }
    if (areExpirat) return Colors.red.shade700;
    if (areAlerta) return Colors.orange.shade800;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final date = context.watch<DateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicule')),
      body: date.seIncarca
          ? const Center(child: CircularProgressIndicator())
          : date.vehicule.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Niciun vehicul adăugat încă.'),
              ),
            )
          : ListView.builder(
              // Padding jos generos - bara de navigare e plutitoare (peste
              // conținut, Scaffold.extendBody), altfel ultimele rânduri
              // rămân ascunse sub ea.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: date.vehicule.length,
              itemBuilder: (context, i) {
                final v = date.vehicule[i];
                return _CardVehicul(
                  vehicul: v,
                  culoareAlerta: _culoareAlerta(date, v.id),
                );
              },
            ),
      // Padding jos - bara de navigare e plutitoare peste conținut
      // (Scaffold.extendBody): înălțimea ei (64) + marginea (10) + safe
      // area de jos (home indicator), altfel butonul rămâne ascuns sub ea.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 94 + MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const VehiculFormScreen())),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _CardVehicul extends StatelessWidget {
  final Vehicul vehicul;
  final Color? culoareAlerta;

  const _CardVehicul({required this.vehicul, this.culoareAlerta});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        // Pătrat cu colțuri teșite (stil iconiță iOS) + bordură, nu cerc -
        // vehiculul se încadrează mai bine într-un dreptunghi decât în cerc.
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1.5,
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: vehicul.fotoUrl.isEmpty
                  ? Icon(
                      Icons.directions_car,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : Image.network(
                      vehicul.fotoUrl,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    ),
            ),
            // Semnalare ITP/Rovinietă/Asigurare/Revizie expirată sau
            // aproape de expirare - roșu dacă ceva e deja expirat,
            // portocaliu dacă e doar în pragul de alertă.
            if (culoareAlerta != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: culoareAlerta,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          vehicul.nr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(vehicul.numeAfisat.isEmpty ? '—' : vehicul.numeAfisat),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VehiculDetaliuScreen(vehiculId: vehicul.id),
          ),
        ),
      ),
    );
  }
}

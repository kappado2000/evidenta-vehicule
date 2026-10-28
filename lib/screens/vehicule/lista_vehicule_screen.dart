import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vehicul.dart';
import '../../providers/date_provider.dart';
import 'vehicul_detaliu_screen.dart';
import 'vehicul_form_screen.dart';

class ListaVehiculeScreen extends StatelessWidget {
  const ListaVehiculeScreen({super.key});

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
                return _CardVehicul(vehicul: v);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const VehiculFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardVehicul extends StatelessWidget {
  final Vehicul vehicul;

  const _CardVehicul({required this.vehicul});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        // Pătrat cu colțuri teșite (stil iconiță iOS) + bordură, nu cerc -
        // vehiculul se încadrează mai bine într-un dreptunghi decât în cerc.
        leading: Container(
          width: 52,
          height: 52,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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

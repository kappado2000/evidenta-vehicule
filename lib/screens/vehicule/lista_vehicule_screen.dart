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
                  padding: const EdgeInsets.all(12),
                  itemCount: date.vehicule.length,
                  itemBuilder: (context, i) {
                    final v = date.vehicule[i];
                    return _CardVehicul(vehicul: v);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VehiculFormScreen()),
        ),
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
        leading: CircleAvatar(
          child: vehicul.fotoUrl.isEmpty
              ? const Icon(Icons.directions_car)
              : ClipOval(
                  child: Image.network(
                    vehicul.fotoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  ),
                ),
        ),
        title: Text(vehicul.nr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asigurare.dart';
import '../../models/itp.dart';
import '../../models/revizie.dart';
import '../../models/rovinieta.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';
import '../asigurari/asigurare_form_screen.dart';
import '../itp/itp_form_screen.dart';
import '../revizii/revizie_form_screen.dart';
import '../rovinieta/rovinieta_form_screen.dart';
import 'vehicul_form_screen.dart';

class VehiculDetaliuScreen extends StatelessWidget {
  final String vehiculId;

  const VehiculDetaliuScreen({super.key, required this.vehiculId});

  @override
  Widget build(BuildContext context) {
    final date = context.watch<DateProvider>();
    final vehicul = date.vehiculDupaId(vehiculId);

    if (vehicul == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicul')),
        body: const Center(child: Text('Vehiculul a fost șters.')),
      );
    }

    final itpuri = date.itpuri.where((i) => i.vehiculId == vehiculId).toList()
      ..sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    final rovinete =
        date.rovinete.where((r) => r.vehiculId == vehiculId).toList()
          ..sort((a, b) =>
              (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    final asigurari =
        date.asigurari.where((a) => a.vehiculId == vehiculId).toList()
          ..sort((a, b) =>
              (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    final revizii =
        date.revizii.where((r) => r.vehiculId == vehiculId).toList()
          ..sort((a, b) =>
              (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicul.nr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VehiculFormScreen(vehicul: vehicul),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirma = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Ștergi vehiculul?'),
                  content: Text(
                      '${vehicul.nr} și toate înregistrările asociate rămân în istoric, doar vehiculul e șters.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Anulează')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Șterge')),
                  ],
                ),
              );
              if (confirma == true) {
                await date.vehiculeRepo.sterge(vehiculId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicul.fotoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(vehicul.fotoUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.fallback),
                    ),
                  const SizedBox(height: 8),
                  Text(vehicul.numeAfisat,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text([
                    if (vehicul.an != null) 'An: ${vehicul.an}',
                    if (vehicul.km != null) 'Km: ${vehicul.km}',
                    if (vehicul.combustibil.isNotEmpty) vehicul.combustibil,
                  ].join(' · ')),
                  if (vehicul.vin.isNotEmpty) Text('VIN: ${vehicul.vin}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Sectiune<Itp>(
            titlu: 'ITP',
            icon: Icons.fact_check_outlined,
            items: itpuri,
            idItem: (i) => i.id,
            subtitluItem: (i) =>
                'Expiră: ${formateazaDataRo(i.dataExpirare)} · ${i.cost.toStringAsFixed(0)} lei',
            onAdauga: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ItpFormScreen(vehiculId: vehiculId),
            )),
            onSterge: (id) => date.itpRepo.sterge(id),
          ),
          _Sectiune<Rovinieta>(
            titlu: 'Rovinietă',
            icon: Icons.route_outlined,
            items: rovinete,
            idItem: (r) => r.id,
            subtitluItem: (r) =>
                '${r.tip} · expiră: ${formateazaDataRo(r.dataExpirare)} · ${r.cost.toStringAsFixed(0)} lei',
            onAdauga: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RovinietaFormScreen(vehiculId: vehiculId),
            )),
            onSterge: (id) => date.rovinietaRepo.sterge(id),
          ),
          _Sectiune<Asigurare>(
            titlu: 'Asigurări',
            icon: Icons.shield_outlined,
            items: asigurari,
            idItem: (a) => a.id,
            subtitluItem: (a) =>
                '${a.tip} · ${a.furnizor} · expiră: ${formateazaDataRo(a.dataExpirare)} · ${a.cost.toStringAsFixed(0)} lei',
            onAdauga: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AsigurareFormScreen(vehiculId: vehiculId),
            )),
            onSterge: (id) => date.asigurariRepo.sterge(id),
          ),
          _Sectiune<Revizie>(
            titlu: 'Revizii',
            icon: Icons.build_outlined,
            items: revizii,
            idItem: (r) => r.id,
            subtitluItem: (r) =>
                '${r.tip.isEmpty ? 'Revizie' : r.tip} · ${formateazaDataRo(r.data)} · ${r.costTotal.toStringAsFixed(0)} lei',
            onAdauga: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RevizieFormScreen(vehiculId: vehiculId),
            )),
            onSterge: (id) => date.reviziiRepo.sterge(id),
          ),
        ],
      ),
    );
  }
}

class _Sectiune<T> extends StatelessWidget {
  final String titlu;
  final IconData icon;
  final List<T> items;
  final String Function(T) idItem;
  final String Function(T) subtitluItem;
  final VoidCallback onAdauga;
  final Future<void> Function(String id) onSterge;

  const _Sectiune({
    required this.titlu,
    required this.icon,
    required this.items,
    required this.idItem,
    required this.subtitluItem,
    required this.onAdauga,
    required this.onSterge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text('$titlu (${items.length})'),
        children: [
          ...items.map((item) => ListTile(
                title: Text(subtitluItem(item)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => onSterge(idItem(item)),
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              onPressed: onAdauga,
              icon: const Icon(Icons.add),
              label: Text('Adaugă $titlu'),
            ),
          ),
        ],
      ),
    );
  }
}

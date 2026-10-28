import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/asigurare.dart';
import '../../models/fisier_atasat.dart';
import '../../models/itp.dart';
import '../../models/revizie.dart';
import '../../models/rovinieta.dart';
import '../../providers/date_provider.dart';
import '../../services/storage_service.dart';
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
      ..sort(
        (a, b) =>
            (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)),
      );
    final rovinete =
        date.rovinete.where((r) => r.vehiculId == vehiculId).toList()..sort(
          (a, b) => (b.timestamp ?? DateTime(0)).compareTo(
            a.timestamp ?? DateTime(0),
          ),
        );
    final asigurari =
        date.asigurari.where((a) => a.vehiculId == vehiculId).toList()..sort(
          (a, b) => (b.timestamp ?? DateTime(0)).compareTo(
            a.timestamp ?? DateTime(0),
          ),
        );
    final revizii = date.revizii.where((r) => r.vehiculId == vehiculId).toList()
      ..sort(
        (a, b) =>
            (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicul.nr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VehiculFormScreen(vehicul: vehicul),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirma = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Ștergi vehiculul?'),
                  content: Text(
                    '${vehicul.nr} și toate înregistrările asociate rămân în istoric, doar vehiculul e șters.',
                  ),
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
                      child: Image.network(
                        vehicul.fotoUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    vehicul.numeAfisat,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    [
                      if (vehicul.an != null) 'An: ${vehicul.an}',
                      if (vehicul.km != null) 'Km: ${vehicul.km}',
                      if (vehicul.combustibil.isNotEmpty) vehicul.combustibil,
                    ].join(' · '),
                  ),
                  if (vehicul.vin.isNotEmpty) Text('VIN: ${vehicul.vin}'),
                  if (vehicul.culoare.isNotEmpty)
                    Text('Culoare: ${vehicul.culoare}'),
                  if (vehicul.putereCP != null)
                    Text('Putere: ${vehicul.putereCP} CP'),
                  if (vehicul.capacitateCilindrica != null)
                    Text('Capacitate: ${vehicul.capacitateCilindrica} cmc'),
                  if (vehicul.anvelope.isNotEmpty)
                    Text('Anvelope: ${vehicul.anvelope}'),
                  if (vehicul.observatii.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(vehicul.observatii),
                  ],
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
            zileRamaseItem: (i) => zilePanaLa(i.dataExpirare),
            onAdauga: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItpFormScreen(vehiculId: vehiculId),
              ),
            ),
            onEditeaza: (itp) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItpFormScreen(vehiculId: vehiculId, itp: itp),
              ),
            ),
            onSterge: (id) => date.itpRepo.sterge(id),
          ),
          _Sectiune<Rovinieta>(
            titlu: 'Rovinietă',
            icon: Icons.toll_outlined,
            items: rovinete,
            idItem: (r) => r.id,
            subtitluItem: (r) =>
                '${r.tip} · expiră: ${formateazaDataRo(r.dataExpirare)} · ${r.cost.toStringAsFixed(0)} lei',
            zileRamaseItem: (r) => zilePanaLa(r.dataExpirare),
            onAdauga: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RovinietaFormScreen(vehiculId: vehiculId),
              ),
            ),
            onEditeaza: (rov) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RovinietaFormScreen(vehiculId: vehiculId, rovinieta: rov),
              ),
            ),
            onSterge: (id) => date.rovinietaRepo.sterge(id),
          ),
          _Sectiune<Asigurare>(
            titlu: 'Asigurări',
            icon: Icons.shield_outlined,
            items: asigurari,
            idItem: (a) => a.id,
            subtitluItem: (a) =>
                '${a.tip} · ${a.furnizor} · expiră: ${formateazaDataRo(a.dataExpirare)} · ${a.cost.toStringAsFixed(0)} lei',
            zileRamaseItem: (a) => zilePanaLa(a.dataExpirare),
            onAdauga: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AsigurareFormScreen(vehiculId: vehiculId),
              ),
            ),
            onEditeaza: (asig) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AsigurareFormScreen(vehiculId: vehiculId, asigurare: asig),
              ),
            ),
            onSterge: (id) => date.asigurariRepo.sterge(id),
          ),
          _Sectiune<Revizie>(
            titlu: 'Revizii',
            icon: Icons.build_outlined,
            items: revizii,
            idItem: (r) => r.id,
            subtitluItem: (r) =>
                '${r.tip.isEmpty ? 'Revizie' : r.tip} · ${formateazaDataRo(r.data)} · ${r.costTotal.toStringAsFixed(0)} lei',
            zileRamaseItem: (r) => zilePanaLa(r.proximData),
            onAdauga: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RevizieFormScreen(vehiculId: vehiculId),
              ),
            ),
            onEditeaza: (rev) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RevizieFormScreen(vehiculId: vehiculId, revizie: rev),
              ),
            ),
            onSterge: (id) => date.reviziiRepo.sterge(id),
          ),
          _SectiuneDocumente(
            titlu: 'Talon',
            icon: Icons.description_outlined,
            fisiere: vehicul.talon,
            dataOwnerUid: date.dataOwnerUid,
            onActualizeaza: (nouaLista) => date.vehiculeRepo.actualizeaza(
              vehicul.id,
              vehicul.copyWith(talon: nouaLista),
            ),
          ),
          _SectiuneDocumente(
            titlu: 'Carte de identitate',
            icon: Icons.badge_outlined,
            fisiere: vehicul.carteIdentitate,
            dataOwnerUid: date.dataOwnerUid,
            onActualizeaza: (nouaLista) => date.vehiculeRepo.actualizeaza(
              vehicul.id,
              vehicul.copyWith(carteIdentitate: nouaLista),
            ),
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
  final int? Function(T) zileRamaseItem;
  final VoidCallback onAdauga;
  final void Function(T item) onEditeaza;
  final Future<void> Function(String id) onSterge;

  const _Sectiune({
    required this.titlu,
    required this.icon,
    required this.items,
    required this.idItem,
    required this.subtitluItem,
    required this.zileRamaseItem,
    required this.onAdauga,
    required this.onEditeaza,
    required this.onSterge,
  });

  /// Verde = relaxat, galben = atenție, portocaliu/roșu = urgent/expirat —
  /// aceleași praguri ca la alertele din Dashboard.
  Color _culoareZile(int zile) {
    if (zile < 0) return Colors.red.shade700;
    if (zile <= 7) return Colors.orange.shade800;
    if (zile <= 30) return Colors.amber.shade800;
    return Colors.green.shade700;
  }

  Future<bool> _confirmaStergere(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ștergi din $titlu?'),
        content: const Text('Înregistrarea nu mai poate fi recuperată.'),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text('$titlu (${items.length})'),
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1),
            Dismissible(
              key: ValueKey(idItem(item)),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Theme.of(context).colorScheme.error,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              confirmDismiss: (_) => _confirmaStergere(context),
              onDismissed: (_) => onSterge(idItem(item)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 13,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(subtitluItem(item)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (zileRamaseItem(item) case final zile?)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _culoareZile(zile),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          zile < 0 ? 'Expirat' : '${zile}z',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () => onEditeaza(item),
              ),
            ),
          ],
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

/// Listă de documente atașate vehiculului (talon / carte de identitate),
/// cu adăugare (poză sau PDF, din `file_picker` ca bytes, nu `dart:io File`
/// — merge și pe web), deschidere în tab nou, și ștergere prin swipe.
class _SectiuneDocumente extends StatefulWidget {
  final String titlu;
  final IconData icon;
  final List<FisierAtasat> fisiere;
  final String dataOwnerUid;
  final Future<void> Function(List<FisierAtasat> nouaLista) onActualizeaza;

  const _SectiuneDocumente({
    required this.titlu,
    required this.icon,
    required this.fisiere,
    required this.dataOwnerUid,
    required this.onActualizeaza,
  });

  @override
  State<_SectiuneDocumente> createState() => _SectiuneDocumenteState();
}

class _SectiuneDocumenteState extends State<_SectiuneDocumente> {
  bool _seIncarca = false;

  Future<bool> _confirmaStergere(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ștergi din ${widget.titlu}?'),
        content: const Text('Fișierul nu mai poate fi recuperat.'),
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

  Future<void> _sterge(FisierAtasat fisier) async {
    await StorageService().sterge(fisier.path);
    final nouaLista = widget.fisiere
        .where((f) => f.path != fisier.path)
        .toList();
    await widget.onActualizeaza(nouaLista);
  }

  Future<void> _adauga() async {
    final rezultat = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (rezultat.isEmpty) return;
    final fisier = rezultat.first;
    final bytes = await fisier.readAsBytes();

    setState(() => _seIncarca = true);
    try {
      final extensie = (fisier.extension ?? '').toLowerCase();
      final contentType = extensie == 'pdf' ? 'application/pdf' : 'image/jpeg';
      final atas = await StorageService().urcaBytes(
        dataOwnerUid: widget.dataOwnerUid,
        subfolder: 'vehicule',
        bytes: bytes,
        numeOriginal: fisier.name,
        contentType: contentType,
      );
      await widget.onActualizeaza([...widget.fisiere, atas]);
    } finally {
      if (mounted) setState(() => _seIncarca = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(widget.icon),
        title: Text('${widget.titlu} (${widget.fisiere.length})'),
        children: [
          for (final fisier in widget.fisiere) ...[
            Dismissible(
              key: ValueKey(fisier.path),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Theme.of(context).colorScheme.error,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              confirmDismiss: (_) => _confirmaStergere(context),
              onDismissed: (_) => _sterge(fisier),
              child: ListTile(
                leading: Icon(
                  fisier.type.contains('pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(fisier.name, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(
                  Uri.parse(fisier.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              onPressed: _seIncarca ? null : _adauga,
              icon: _seIncarca
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text('Adaugă ${widget.titlu}'),
            ),
          ),
        ],
      ),
    );
  }
}

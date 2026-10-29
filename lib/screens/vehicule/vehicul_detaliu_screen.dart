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

class VehiculDetaliuScreen extends StatefulWidget {
  final String vehiculId;

  const VehiculDetaliuScreen({super.key, required this.vehiculId});

  @override
  State<VehiculDetaliuScreen> createState() => _VehiculDetaliuScreenState();
}

class _VehiculDetaliuScreenState extends State<VehiculDetaliuScreen> {
  bool _arataDocumente = false;
  // Stare de extindere a celor 4 categorii, ținută AICI (în ecranul părinte,
  // care nu e niciodată eliminat din arbore la derulare) - nu în fiecare
  // card în parte: un card e un element din ListView și Flutter îi distruge
  // starea internă când iese suficient din ecran la scroll, resetând
  // extinderea la închis quando revii la el. Acordeon: o singură categorie
  // deschisă simultan - la deschiderea uneia noi, cea veche se închide.
  String? _categorieExtinsa;

  void _comutaCategorie(String titlu) {
    setState(() {
      _categorieExtinsa = _categorieExtinsa == titlu ? null : titlu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculId = widget.vehiculId;
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
      body: Column(
        children: [
          // Poza pe toată lățimea ecranului, scoasă din card - nu mai e
          // limitată de padding-ul listei de dedesubt.
          if (vehicul.fotoUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => _FotoIntreagaScreen(url: vehicul.fotoUrl),
                ),
              ),
              child: Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: Image.network(
                  vehicul.fotoUrl,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              // Padding jos generos - bara de navigare e plutitoare (peste
              // conținut, Scaffold.extendBody), altfel categoria Revizii
              // (ultima din listă) rămâne ascunsă sub ea.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicul.numeAfisat,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        // Atingi descrierea/observațiile ca să arăți/ascunzi
                        // talonul și cartea de identitate - nu mai stau mereu
                        // vizibile sub datele vehiculului.
                        InkWell(
                          onTap: () => setState(
                            () => _arataDocumente = !_arataDocumente,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2 coloane independente, nu rânduri perechi -
                              // dacă un câmp din dreapta se rupe pe 2 linii
                              // (ex. VIN), nu mai trage după el un rând gol
                              // în stânga: fiecare coloană curge pe cont
                              // propriu. Cardul ocupă mai puțin pe înălțime,
                              // lăsând butoanele celor 4 categorii să încapă
                              // mai bine pe ecran.
                              Builder(
                                builder: (context) {
                                  final campuri = [
                                    if (vehicul.an != null)
                                      _randDate(context, 'An', '${vehicul.an}'),
                                    if (vehicul.km != null)
                                      _randDate(context, 'Km', '${vehicul.km}'),
                                    if (vehicul.combustibil.isNotEmpty)
                                      _randDate(
                                        context,
                                        'Combustibil',
                                        vehicul.combustibil,
                                      ),
                                    if (vehicul.vin.isNotEmpty)
                                      _randDate(context, 'VIN', vehicul.vin),
                                    if (vehicul.culoare.isNotEmpty)
                                      _randDate(
                                        context,
                                        'Culoare',
                                        vehicul.culoare,
                                      ),
                                    if (vehicul.putereCP != null)
                                      _randDate(
                                        context,
                                        'Putere',
                                        '${vehicul.putereCP} CP',
                                      ),
                                    if (vehicul.capacitateCilindrica != null)
                                      _randDate(
                                        context,
                                        'Capacitate',
                                        '${vehicul.capacitateCilindrica} cmc',
                                      ),
                                    if (vehicul.anvelope.isNotEmpty)
                                      _randDate(
                                        context,
                                        'Anvelope',
                                        vehicul.anvelope,
                                      ),
                                  ];
                                  final coloanaStanga = [
                                    for (var i = 0; i < campuri.length; i += 2)
                                      campuri[i],
                                  ];
                                  final coloanaDreapta = [
                                    for (var i = 1; i < campuri.length; i += 2)
                                      campuri[i],
                                  ];
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: coloanaStanga,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: coloanaDreapta,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _arataDocumente
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _arataDocumente ? 'Ascunde detaliile' : 'Atinge pentru observații, talon și carte de identitate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_arataDocumente) ...[
                          const Divider(height: 24),
                          if (vehicul.observatii.isNotEmpty) ...[
                            _randDate(
                              context,
                              'Observații',
                              vehicul.observatii,
                            ),
                            const SizedBox(height: 8),
                          ],
                          _SectiuneDocumente(
                            titlu: 'Talon',
                            icon: Icons.description_outlined,
                            fisiere: vehicul.talon,
                            dataOwnerUid: date.dataOwnerUid,
                            onActualizeaza: (nouaLista) =>
                                date.vehiculeRepo.actualizeaza(
                                  vehicul.id,
                                  vehicul.copyWith(talon: nouaLista),
                                ),
                          ),
                          _SectiuneDocumente(
                            titlu: 'Carte de identitate',
                            icon: Icons.badge_outlined,
                            fisiere: vehicul.carteIdentitate,
                            dataOwnerUid: date.dataOwnerUid,
                            onActualizeaza: (nouaLista) =>
                                date.vehiculeRepo.actualizeaza(
                                  vehicul.id,
                                  vehicul.copyWith(carteIdentitate: nouaLista),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Sectiune<Itp>(
                  key: const PageStorageKey('sectiune_itp'),
                  titlu: 'ITP',
                  icon: Icons.fact_check_outlined,
                  extins: _categorieExtinsa == 'ITP',
                  onToggle: () => _comutaCategorie('ITP'),
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
                      builder: (_) =>
                          ItpFormScreen(vehiculId: vehiculId, itp: itp),
                    ),
                  ),
                  onSterge: (id) => date.itpRepo.sterge(id),
                ),
                _Sectiune<Rovinieta>(
                  key: const PageStorageKey('sectiune_rovinieta'),
                  titlu: 'Rovinietă',
                  icon: Icons.toll_outlined,
                  extins: _categorieExtinsa == 'Rovinietă',
                  onToggle: () => _comutaCategorie('Rovinietă'),
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
                      builder: (_) => RovinietaFormScreen(
                        vehiculId: vehiculId,
                        rovinieta: rov,
                      ),
                    ),
                  ),
                  onSterge: (id) => date.rovinietaRepo.sterge(id),
                ),
                _Sectiune<Asigurare>(
                  key: const PageStorageKey('sectiune_asigurari'),
                  titlu: 'Asigurări',
                  icon: Icons.shield_outlined,
                  extins: _categorieExtinsa == 'Asigurări',
                  onToggle: () => _comutaCategorie('Asigurări'),
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
                      builder: (_) => AsigurareFormScreen(
                        vehiculId: vehiculId,
                        asigurare: asig,
                      ),
                    ),
                  ),
                  onSterge: (id) => date.asigurariRepo.sterge(id),
                ),
                _Sectiune<Revizie>(
                  key: const PageStorageKey('sectiune_revizii'),
                  titlu: 'Revizii',
                  icon: Icons.build_outlined,
                  extins: _categorieExtinsa == 'Revizii',
                  onToggle: () => _comutaCategorie('Revizii'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imaginea vehiculului pe tot ecranul, deschisă prin dublu-tap pe poza din
/// cardul vehiculului — zoom/pan cu InteractiveViewer, fundal negru.
class _FotoIntreagaScreen extends StatelessWidget {
  final String url;

  const _FotoIntreagaScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          ),
        ),
      ),
    );
  }
}

/// Rând „etichetă: valoare" pentru cardul vehiculului — etichetă bolduită,
/// valoare normală, scris mai mic decât titlul (userul a cerut explicit
/// această ierarhie vizuală).
Widget _randDate(BuildContext context, String eticheta, String valoare) {
  final culoare = Theme.of(context).colorScheme.onSurface;
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: culoare),
        children: [
          TextSpan(
            text: '$eticheta: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: valoare),
        ],
      ),
    ),
  );
}

class _Sectiune<T> extends StatelessWidget {
  final String titlu;
  final IconData icon;
  // Starea de extindere vine din ecranul părinte (vezi `_categorieExtinsa`
  // pe `_VehiculDetaliuScreenState`) - ținută aici local, un card expandat
  // care iese din ecran la derulare e distrus de Flutter (element din
  // ListView) și starea lui s-ar pierde la revenire.
  final bool extins;
  final VoidCallback onToggle;
  final List<T> items;
  final String Function(T) idItem;
  final String Function(T) subtitluItem;
  final int? Function(T) zileRamaseItem;
  final VoidCallback onAdauga;
  final void Function(T item) onEditeaza;
  final Future<void> Function(String id) onSterge;

  const _Sectiune({
    super.key,
    required this.titlu,
    required this.icon,
    required this.extins,
    required this.onToggle,
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

  /// Starea curentă a categoriei, pe antet - DOAR din cea mai recentă
  /// înregistrare (`items` e deja sortat descrescător după timestamp), nu
  /// minimul din tot istoricul: o revizie/asigurare veche, deja înlocuită
  /// de una nouă, nu mai e relevantă și n-ar trebui să arate "Expirat"
  /// pentru vehiculul curent.
  int? _zileMinime() {
    if (items.isEmpty) return null;
    return zileRamaseItem(items.first);
  }

  @override
  Widget build(BuildContext context) {
    final zile = _zileMinime();
    final culori = Theme.of(context).colorScheme;
    // Text "gravat" în buton: umbră întunecată sus-stânga + reflex deschis
    // jos-dreapta, dă impresia de literă scobită în material, nu imprimată.
    final stilGravat = TextStyle(
      color: culori.onSurface.withValues(alpha: 0.85),
      shadows: [
        Shadow(
          offset: const Offset(-1, -1),
          blurRadius: 1,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        Shadow(
          offset: const Offset(1, 1),
          blurRadius: 1,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Contur subțire, ton mai închis decât fundalul butonului.
        border: Border.all(
          color: Color.alphaBlend(
            Colors.black.withValues(alpha: 0.18),
            culori.surfaceContainerHighest,
          ),
          width: 1,
        ),
        // Gradient ușor (mai deschis sus, ton normal jos) - simulează o
        // suprafață curbată, ridicată. Umbră explicită, dar foarte mică.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.5),
              culori.surfaceContainerHighest,
            ),
            culori.surfaceContainerHighest,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: titlu,
                        style: stilGravat,
                        children: [
                          TextSpan(
                            text: ' - ${items.length}',
                            style: stilGravat.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (zile != null) ...[
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
                    const SizedBox(width: 8),
                  ],
                  Icon(extins ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (extins) ...[
            for (final (index, item) in items.indexed)
              // O singură culoare (albastru) pentru toate cele 4 categorii
              // când sunt deschise, nu mai e diferită per categorie - plus
              // bordură închisă și rânduri mai înguste pe înălțime.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, Colors.blue, 0.18),
                  border: Border.all(
                    color: Colors.blue.shade900.withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Dismissible(
                  key: ValueKey(idItem(item)),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: culori.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline, color: culori.onError),
                  ),
                  confirmDismiss: (_) => _confirmaStergere(context),
                  onDismissed: (_) => onSterge(idItem(item)),
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                    leading: CircleAvatar(
                      radius: 11,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text(
                      subtitluItem(item),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => onEditeaza(item),
                  ),
                ),
              ),
            Container(
              color: culori.surface,
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: culori.primary,
                  foregroundColor: culori.onPrimary,
                ),
                onPressed: onAdauga,
                icon: const Icon(Icons.add),
                label: Text('Adaugă $titlu'),
              ),
            ),
          ],
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
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
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
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _seIncarca ? null : _adauga,
            icon: _seIncarca
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text('Adaugă ${widget.titlu}'),
          ),
        ),
      ],
    );
  }
}

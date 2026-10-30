import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/vehicul.dart';
import '../../providers/date_provider.dart';
import '../../services/storage_service.dart';
import '../../services/vin_scanner.dart';

const List<String> _tipuriCombustibil = [
  'Benzină',
  'Diesel',
  'GPL',
  'Hibrid',
  'Electric',
];

/// Formular adăugare/editare vehicul. `vehicul == null` => adăugare nouă.
class VehiculFormScreen extends StatefulWidget {
  final Vehicul? vehicul;

  const VehiculFormScreen({super.key, this.vehicul});

  @override
  State<VehiculFormScreen> createState() => _VehiculFormScreenState();
}

class _VehiculFormScreenState extends State<VehiculFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nrCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _anCtrl;
  late final TextEditingController _kmCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _culoareCtrl;
  late final TextEditingController _putereCtrl;
  late final TextEditingController _capacitateCtrl;
  late final TextEditingController _anvelopeCtrl;
  late final TextEditingController _observatiiCtrl;
  String _combustibil = '';
  String _fotoUrl = '';
  String _fotoPath = '';
  XFile? _fotoNoua;
  bool _seSalveaza = false;
  bool _seScaneazaVin = false;

  bool get _editare => widget.vehicul != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicul;
    _nrCtrl = TextEditingController(text: v?.nr ?? '');
    _marcaCtrl = TextEditingController(text: v?.marca ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _anCtrl = TextEditingController(text: v?.an?.toString() ?? '');
    _kmCtrl = TextEditingController(text: v?.km?.toString() ?? '');
    // Ascultător ca butoanele din dreptul câmpului VIN (copiere/scanare) să
    // se actualizeze live în funcție de conținut, nu doar la deschiderea
    // formularului.
    _vinCtrl = TextEditingController(text: v?.vin ?? '')
      ..addListener(() => setState(() {}));
    _culoareCtrl = TextEditingController(text: v?.culoare ?? '');
    _putereCtrl = TextEditingController(text: v?.putereCP?.toString() ?? '');
    _capacitateCtrl = TextEditingController(
      text: v?.capacitateCilindrica?.toString() ?? '',
    );
    _anvelopeCtrl = TextEditingController(text: v?.anvelope ?? '');
    _observatiiCtrl = TextEditingController(text: v?.observatii ?? '');
    _combustibil = v?.combustibil ?? '';
    _fotoUrl = v?.fotoUrl ?? '';
    _fotoPath = v?.fotoPath ?? '';
  }

  @override
  void dispose() {
    _nrCtrl.dispose();
    _marcaCtrl.dispose();
    _modelCtrl.dispose();
    _anCtrl.dispose();
    _kmCtrl.dispose();
    _vinCtrl.dispose();
    _culoareCtrl.dispose();
    _putereCtrl.dispose();
    _capacitateCtrl.dispose();
    _anvelopeCtrl.dispose();
    _observatiiCtrl.dispose();
    super.dispose();
  }

  Future<void> _alegeFoto() async {
    final fisier = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (fisier == null) return;

    // Decupare manuală: userul alege singur cadrul fotografiei, fără
    // raport de aspect impus.
    if (!mounted) return;
    final decupat = await ImageCropper().cropImage(
      sourcePath: fisier.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Decupează fotografia',
          lockAspectRatio: false,
          freeStyleCropEnabled: true,
        ),
        IOSUiSettings(
          title: 'Decupează fotografia',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
        WebUiSettings(context: context),
      ],
    );
    if (decupat == null) return;

    final bytes = await decupat.readAsBytes();
    setState(
      () => _fotoNoua = XFile.fromData(
        bytes,
        name: fisier.name,
        mimeType: 'image/jpeg',
      ),
    );
  }

  /// Fotografiază VIN-ul (parbriz, montant ușă sau talon) și completează
  /// automat câmpul, dacă recunoaște o serie de 17 caractere validă. Doar
  /// pe iOS/Android — pe web `google_mlkit_text_recognition` nu rulează.
  Future<void> _scaneazaVin() async {
    final fisier = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (fisier == null) return;

    setState(() => _seScaneazaVin = true);
    try {
      final vin = await recunoasteVinDinFisier(fisier.path);
      if (!mounted) return;
      if (vin != null) {
        setState(() => _vinCtrl.text = vin);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('VIN găsit: $vin')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nu am găsit un VIN valid în poză. Încearcă din nou, cu mai multă lumină, sau completează-l manual.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _seScaneazaVin = false);
    }
  }

  void _copiazaVin() {
    Clipboard.setData(ClipboardData(text: _vinCtrl.text.trim()));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Serie de șasiu copiată.')));
  }

  Future<void> _salveaza() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _seSalveaza = true);

    final date = context.read<DateProvider>();
    try {
      var fotoUrl = _fotoUrl;
      var fotoPath = _fotoPath;

      if (_fotoNoua != null) {
        final atas = await StorageService().urca(
          dataOwnerUid: date.dataOwnerUid,
          subfolder: 'vehicule',
          fisier: _fotoNoua!,
          numeOriginal: _fotoNoua!.name,
          contentType: 'image/jpeg',
        );
        fotoUrl = atas.url;
        fotoPath = atas.path;
      }

      final vehicul = Vehicul(
        id: widget.vehicul?.id ?? '',
        nr: _nrCtrl.text.trim(),
        marca: _marcaCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        an: int.tryParse(_anCtrl.text),
        km: int.tryParse(_kmCtrl.text),
        vin: _vinCtrl.text.trim(),
        combustibil: _combustibil,
        culoare: _culoareCtrl.text.trim(),
        observatii: _observatiiCtrl.text.trim(),
        putereCP: num.tryParse(_putereCtrl.text),
        capacitateCilindrica: num.tryParse(_capacitateCtrl.text),
        anvelope: _anvelopeCtrl.text.trim(),
        fotoUrl: fotoUrl,
        fotoPath: fotoPath,
        talon: widget.vehicul?.talon ?? const [],
        carteIdentitate: widget.vehicul?.carteIdentitate ?? const [],
      );

      if (_editare) {
        await date.vehiculeRepo.actualizeaza(vehicul.id, vehicul);
      } else {
        await date.vehiculeRepo.adauga(vehicul);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Eroare: $e')));
      }
    } finally {
      if (mounted) setState(() => _seSalveaza = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editare ? 'Editează vehicul' : 'Vehicul nou'),
        actions: [
          IconButton(
            onPressed: _seSalveaza ? null : _salveaza,
            icon: _seSalveaza
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Padding jos generos - bara de navigare e plutitoare (peste
          // conținut, Scaffold.extendBody), altfel ultimul câmp (Observații)
          // rămâne ascuns sub ea.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          children: [
            Center(
              child: GestureDetector(
                onTap: _alegeFoto,
                // Fără poză - pătrat fix cu iconiță (stil iconiță iOS). Cu
                // poză - fără lățime/înălțime fixă, conturul se lipește de
                // marginea reală a pozei, nu de un cadru pătrat cu benzi
                // goale pe laturi (vehiculul întreg trebuie să încapă,
                // contain, nu cover).
                child: (_fotoNoua == null && _fotoUrl.isEmpty)
                    ? Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 36,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(
                          maxWidth: 160,
                          maxHeight: 160,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: _fotoNoua != null
                            ? FutureBuilder<Uint8List>(
                                future: _fotoNoua!.readAsBytes(),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return Image.memory(
                                    snap.data!,
                                    fit: BoxFit.contain,
                                  );
                                },
                              )
                            : Image.network(
                                _fotoUrl,
                                fit: BoxFit.contain,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nrCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Număr înmatriculare *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoriu' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marcaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Marcă',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'An fabricație',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Km curent',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _combustibil.isEmpty ? null : _combustibil,
              decoration: const InputDecoration(
                labelText: 'Combustibil',
                border: OutlineInputBorder(),
              ),
              items: _tipuriCombustibil
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _combustibil = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vinCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'VIN (serie șasiu)',
                border: const OutlineInputBorder(),
                // Dacă seria e deja completată, butonul principal devine
                // copierea ei (cel mai folosit pas la acel moment), iar
                // scanarea cu camera rămâne disponibilă ca a doua opțiune,
                // pentru rescanare.
                suffixIcon: kIsWeb
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_vinCtrl.text.trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Copiază seria',
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: _copiazaVin,
                            ),
                          IconButton(
                            tooltip: 'Scanează VIN cu camera',
                            icon: _seScaneazaVin
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt_outlined),
                            onPressed: _seScaneazaVin ? null : _scaneazaVin,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _putereCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Putere (CP)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capacitateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacitate (cmc)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _culoareCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Culoare',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _anvelopeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Anvelope',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observatiiCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observații',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _editare
                  ? 'Talonul și cartea de identitate se gestionează din ecranul vehiculului.'
                  : 'Talonul și cartea de identitate se adaugă din ecranul vehiculului, după salvare.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

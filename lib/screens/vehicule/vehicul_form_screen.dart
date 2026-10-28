import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/vehicul.dart';
import '../../providers/date_provider.dart';
import '../../services/storage_service.dart';

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
    _vinCtrl = TextEditingController(text: v?.vin ?? '');
    _culoareCtrl = TextEditingController(text: v?.culoare ?? '');
    _putereCtrl = TextEditingController(text: v?.putereCP?.toString() ?? '');
    _capacitateCtrl =
        TextEditingController(text: v?.capacitateCilindrica?.toString() ?? '');
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
    final fisier =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (fisier != null) setState(() => _fotoNoua = fisier);
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
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _alegeFoto,
                child: _fotoNoua != null
                    ? FutureBuilder<Uint8List>(
                        future: _fotoNoua!.readAsBytes(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const CircleAvatar(
                                radius: 48,
                                child: CircularProgressIndicator());
                          }
                          return CircleAvatar(
                            radius: 48,
                            backgroundImage: MemoryImage(snap.data!),
                          );
                        },
                      )
                    : CircleAvatar(
                        radius: 48,
                        child: _fotoUrl.isEmpty
                            ? const Icon(Icons.add_a_photo_outlined, size: 32)
                            : ClipOval(
                                child: Image.network(
                                  _fotoUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.fallback,
                                ),
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nrCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Număr înmatriculare *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoriu' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _marcaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Marcă', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Model', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _anCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'An fabricație', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _kmCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Km curent', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _combustibil.isEmpty ? null : _combustibil,
              decoration: const InputDecoration(
                  labelText: 'Combustibil', border: OutlineInputBorder()),
              items: _tipuriCombustibil
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _combustibil = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vinCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'VIN (serie șasiu)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _putereCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Putere (CP)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _capacitateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Capacitate (cmc)', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _culoareCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Culoare', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _anvelopeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Anvelope', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observatiiCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Observații', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

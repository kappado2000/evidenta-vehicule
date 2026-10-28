import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/revizie.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';

class RevizieFormScreen extends StatefulWidget {
  final String vehiculId;
  final Revizie? revizie;

  const RevizieFormScreen({super.key, required this.vehiculId, this.revizie});

  @override
  State<RevizieFormScreen> createState() => _RevizieFormScreenState();
}

class _RevizieFormScreenState extends State<RevizieFormScreen> {
  late final TextEditingController _tipCtrl;
  late String _data;
  late final TextEditingController _kmCtrl;
  late final TextEditingController _serviceCtrl;
  late final TextEditingController _locatieCtrl;
  late final TextEditingController _pieseCtrl;
  late final TextEditingController _costManoperaCtrl;
  late final TextEditingController _costPieseCtrl;
  late final TextEditingController _proximKmCtrl;
  late String _proximData;
  late final TextEditingController _observatiiCtrl;
  bool _seSalveaza = false;

  bool get _editare => widget.revizie != null;

  @override
  void initState() {
    super.initState();
    final r = widget.revizie;
    _tipCtrl = TextEditingController(text: r?.tip ?? '');
    _data = r?.data ?? azIso();
    _kmCtrl = TextEditingController(text: r?.km?.toString() ?? '');
    _serviceCtrl = TextEditingController(text: r?.service ?? '');
    _locatieCtrl = TextEditingController(text: r?.locatie ?? '');
    _pieseCtrl = TextEditingController(text: r?.piese ?? '');
    _costManoperaCtrl = TextEditingController(
      text: r?.costManopera.toString() ?? '',
    );
    _costPieseCtrl = TextEditingController(text: r?.costPiese.toString() ?? '');
    _proximKmCtrl = TextEditingController(text: r?.proximKm?.toString() ?? '');
    _proximData = r?.proximData ?? adaugaAniIso(_data, 1) ?? '';
    _observatiiCtrl = TextEditingController(text: r?.observatii ?? '');
  }

  @override
  void dispose() {
    _tipCtrl.dispose();
    _kmCtrl.dispose();
    _serviceCtrl.dispose();
    _locatieCtrl.dispose();
    _pieseCtrl.dispose();
    _costManoperaCtrl.dispose();
    _costPieseCtrl.dispose();
    _proximKmCtrl.dispose();
    _observatiiCtrl.dispose();
    super.dispose();
  }

  Future<void> _aleg(bool dataPrincipala) async {
    final initial =
        DateTime.tryParse(dataPrincipala ? _data : _proximData) ??
        DateTime.now();
    final rezultat = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (rezultat == null) return;
    final iso =
        '${rezultat.year.toString().padLeft(4, '0')}-${rezultat.month.toString().padLeft(2, '0')}-${rezultat.day.toString().padLeft(2, '0')}';
    setState(() {
      if (dataPrincipala) {
        _data = iso;
        // Interval implicit de 1 an până la proxima revizie - se
        // recalculează automat, rămâne editabilă manual după aceea.
        _proximData = adaugaAniIso(iso, 1) ?? _proximData;
      } else {
        _proximData = iso;
      }
    });
  }

  Future<void> _salveaza() async {
    setState(() => _seSalveaza = true);
    final date = context.read<DateProvider>();
    final costManopera = num.tryParse(_costManoperaCtrl.text) ?? 0;
    final costPiese = num.tryParse(_costPieseCtrl.text) ?? 0;
    final revizie = Revizie(
      id: widget.revizie?.id ?? '',
      vehiculId: widget.vehiculId,
      tip: _tipCtrl.text.trim(),
      data: _data,
      km: int.tryParse(_kmCtrl.text),
      service: _serviceCtrl.text.trim(),
      locatie: _locatieCtrl.text.trim(),
      piese: _pieseCtrl.text.trim(),
      costManopera: costManopera,
      costPiese: costPiese,
      costTotal: costManopera + costPiese,
      proximKm: int.tryParse(_proximKmCtrl.text),
      proximData: _proximData,
      observatii: _observatiiCtrl.text.trim(),
      documente: widget.revizie?.documente ?? const [],
    );
    try {
      if (_editare) {
        await date.reviziiRepo.actualizeaza(revizie.id, revizie);
      } else {
        await date.reviziiRepo.adauga(revizie);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _seSalveaza = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editare ? 'Editează revizie' : 'Revizie nouă'),
        actions: [
          IconButton(
            onPressed: _seSalveaza ? null : _salveaza,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _tipCtrl,
            decoration: const InputDecoration(
              labelText: 'Tip revizie',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Data'),
            subtitle: Text(formateazaDataRo(_data)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _aleg(true),
          ),
          TextField(
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Km la revizie',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serviceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _locatieCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Locație',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pieseCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Piese schimbate',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _costManoperaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost manoperă',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _costPieseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost piese',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _proximKmCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Proxima revizie (km)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Proxima revizie (dată)'),
            subtitle: Text(
              _proximData.isEmpty
                  ? 'Alege o dată'
                  : formateazaDataRo(_proximData),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _aleg(false),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observatiiCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observații',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rovinieta.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';

class RovinietaFormScreen extends StatefulWidget {
  final String vehiculId;
  final Rovinieta? rovinieta;

  const RovinietaFormScreen({
    super.key,
    required this.vehiculId,
    this.rovinieta,
  });

  @override
  State<RovinietaFormScreen> createState() => _RovinietaFormScreenState();
}

class _RovinietaFormScreenState extends State<RovinietaFormScreen> {
  late String _tip;
  late String _dataInceput;
  late String _dataExpirare;
  late final TextEditingController _costCtrl;
  bool _seSalveaza = false;

  bool get _editare => widget.rovinieta != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rovinieta;
    _tip = r?.tip ?? 'anuala';
    _dataInceput = r?.dataInceput ?? azIso();
    _dataExpirare = r?.dataExpirare ?? '';
    _costCtrl = TextEditingController(text: r?.cost.toString() ?? '');
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _aleg(bool inceput) async {
    final initial =
        DateTime.tryParse(inceput ? _dataInceput : _dataExpirare) ??
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
      if (inceput) {
        _dataInceput = iso;
      } else {
        _dataExpirare = iso;
      }
    });
  }

  Future<void> _salveaza() async {
    if (_dataExpirare.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alege data expirării.')));
      return;
    }
    setState(() => _seSalveaza = true);
    final date = context.read<DateProvider>();
    final rov = Rovinieta(
      id: widget.rovinieta?.id ?? '',
      vehiculId: widget.vehiculId,
      tip: _tip,
      dataInceput: _dataInceput,
      dataExpirare: _dataExpirare,
      cost: num.tryParse(_costCtrl.text) ?? 0,
      documente: widget.rovinieta?.documente ?? const [],
    );
    try {
      if (_editare) {
        await date.rovinietaRepo.actualizeaza(rov.id, rov);
      } else {
        await date.rovinietaRepo.adauga(rov);
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
        title: Text(_editare ? 'Editează rovinietă' : 'Rovinietă nouă'),
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
          DropdownButtonFormField<String>(
            initialValue: _tip,
            decoration: const InputDecoration(
              labelText: 'Tip',
              border: OutlineInputBorder(),
            ),
            items: tipuriRovinieta
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tip = v ?? 'anuala'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Data început'),
            subtitle: Text(formateazaDataRo(_dataInceput)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _aleg(true),
          ),
          ListTile(
            title: const Text('Data expirării *'),
            subtitle: Text(
              _dataExpirare.isEmpty
                  ? 'Alege o dată'
                  : formateazaDataRo(_dataExpirare),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _aleg(false),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cost (lei)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

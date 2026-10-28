import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asigurare.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';

class AsigurareFormScreen extends StatefulWidget {
  final String vehiculId;

  const AsigurareFormScreen({super.key, required this.vehiculId});

  @override
  State<AsigurareFormScreen> createState() => _AsigurareFormScreenState();
}

class _AsigurareFormScreenState extends State<AsigurareFormScreen> {
  String _tip = 'RCA';
  String _dataInceput = azIso();
  String _dataExpirare = '';
  final _furnizorCtrl = TextEditingController();
  final _politaCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _observatiiCtrl = TextEditingController();
  bool _seSalveaza = false;

  @override
  void dispose() {
    _furnizorCtrl.dispose();
    _politaCtrl.dispose();
    _costCtrl.dispose();
    _observatiiCtrl.dispose();
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
    final asig = Asigurare(
      id: '',
      vehiculId: widget.vehiculId,
      tip: _tip,
      furnizor: _furnizorCtrl.text.trim(),
      polita: _politaCtrl.text.trim(),
      dataInceput: _dataInceput,
      dataExpirare: _dataExpirare,
      cost: num.tryParse(_costCtrl.text) ?? 0,
      observatii: _observatiiCtrl.text.trim(),
    );
    try {
      await date.asigurariRepo.adauga(asig);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _seSalveaza = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asigurare nouă'),
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
                labelText: 'Tip', border: OutlineInputBorder()),
            items: tipuriAsigurare
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tip = v ?? 'RCA'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _furnizorCtrl,
            decoration: const InputDecoration(
                labelText: 'Furnizor', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _politaCtrl,
            decoration: const InputDecoration(
                labelText: 'Număr poliță', border: OutlineInputBorder()),
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
            subtitle: Text(_dataExpirare.isEmpty
                ? 'Alege o dată'
                : formateazaDataRo(_dataExpirare)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _aleg(false),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Cost (lei)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observatiiCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Observații', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

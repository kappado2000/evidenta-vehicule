import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/itp.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';

class ItpFormScreen extends StatefulWidget {
  final String vehiculId;

  const ItpFormScreen({super.key, required this.vehiculId});

  @override
  State<ItpFormScreen> createState() => _ItpFormScreenState();
}

class _ItpFormScreenState extends State<ItpFormScreen> {
  String _dataEfectuare = azIso();
  String _dataExpirare = '';
  final _costCtrl = TextEditingController();
  bool _seSalveaza = false;

  @override
  void dispose() {
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _aleg(bool efectuare) async {
    final initial = DateTime.tryParse(
            efectuare ? _dataEfectuare : _dataExpirare) ??
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
      if (efectuare) {
        _dataEfectuare = iso;
      } else {
        _dataExpirare = iso;
      }
    });
  }

  Future<void> _salveaza() async {
    if (_dataExpirare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alege data expirării.')));
      return;
    }
    setState(() => _seSalveaza = true);
    final date = context.read<DateProvider>();
    final itp = Itp(
      id: '',
      vehiculId: widget.vehiculId,
      dataEfectuare: _dataEfectuare,
      dataExpirare: _dataExpirare,
      cost: num.tryParse(_costCtrl.text) ?? 0,
    );
    try {
      await date.itpRepo.adauga(itp);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _seSalveaza = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ITP nou'),
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
          ListTile(
            title: const Text('Data efectuării'),
            subtitle: Text(formateazaDataRo(_dataEfectuare)),
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
            decoration:
                const InputDecoration(labelText: 'Cost (lei)', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

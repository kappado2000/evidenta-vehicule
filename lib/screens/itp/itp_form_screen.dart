import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/itp.dart';
import '../../providers/date_provider.dart';
import '../../utils/date_utils.dart';

class ItpFormScreen extends StatefulWidget {
  final String vehiculId;
  final Itp? itp;

  const ItpFormScreen({super.key, required this.vehiculId, this.itp});

  @override
  State<ItpFormScreen> createState() => _ItpFormScreenState();
}

class _ItpFormScreenState extends State<ItpFormScreen> {
  late String _dataEfectuare;
  late String _dataExpirare;
  late final TextEditingController _costCtrl;
  bool _seSalveaza = false;
  // Valabilitate ITP aleasă de user (1 sau 2 ani) - folosită doar pentru
  // calculul automat al datei de expirare, nu se salvează separat.
  int _valabilitateAni = 2;

  bool get _editare => widget.itp != null;

  @override
  void initState() {
    super.initState();
    final i = widget.itp;
    _dataEfectuare = i?.dataEfectuare ?? azIso();
    _dataExpirare =
        i?.dataExpirare ?? adaugaAniIso(_dataEfectuare, _valabilitateAni) ?? '';
    _costCtrl = TextEditingController(text: i?.cost.toString() ?? '');
  }

  void _recalculeazaExpirare() {
    setState(
      () => _dataExpirare =
          adaugaAniIso(_dataEfectuare, _valabilitateAni) ?? _dataExpirare,
    );
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _aleg(bool efectuare) async {
    final initial =
        DateTime.tryParse(efectuare ? _dataEfectuare : _dataExpirare) ??
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
    // Calcul automat al expirării pe baza datei efectuării + valabilitatea
    // aleasă - rămâne editabilă manual oricând după aceea.
    if (efectuare) _recalculeazaExpirare();
  }

  Future<void> _salveaza() async {
    if (_dataExpirare.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alege data expirării.')));
      return;
    }
    setState(() => _seSalveaza = true);
    final date = context.read<DateProvider>();
    final itp = Itp(
      id: widget.itp?.id ?? '',
      vehiculId: widget.vehiculId,
      dataEfectuare: _dataEfectuare,
      dataExpirare: _dataExpirare,
      cost: num.tryParse(_costCtrl.text) ?? 0,
      documente: widget.itp?.documente ?? const [],
    );
    try {
      if (_editare) {
        await date.itpRepo.actualizeaza(itp.id, itp);
      } else {
        await date.itpRepo.adauga(itp);
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
        title: Text(_editare ? 'Editează ITP' : 'ITP nou'),
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
          Text(
            'Valabilitate ITP',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1 an')),
              ButtonSegment(value: 2, label: Text('2 ani')),
            ],
            selected: {_valabilitateAni},
            onSelectionChanged: (selectie) {
              setState(() => _valabilitateAni = selectie.first);
              _recalculeazaExpirare();
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Data efectuării'),
            subtitle: Text(formateazaDataRo(_dataEfectuare)),
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

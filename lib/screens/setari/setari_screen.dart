import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/date_provider.dart';

class SetariScreen extends StatefulWidget {
  const SetariScreen({super.key});

  @override
  State<SetariScreen> createState() => _SetariScreenState();
}

class _SetariScreenState extends State<SetariScreen> {
  late TextEditingController _itpCtrl;
  late TextEditingController _rovCtrl;
  late TextEditingController _asigCtrl;
  late TextEditingController _revCtrl;
  int _oraNotificare = 8;
  bool _initializat = false;

  void _initializeaza(SetariAlerte s) {
    if (_initializat) return;
    _itpCtrl = TextEditingController(text: s.alertaITP.toString());
    _rovCtrl = TextEditingController(text: s.alertaRovinieta.toString());
    _asigCtrl = TextEditingController(text: s.alertaAsigurare.toString());
    _revCtrl = TextEditingController(text: s.alertaRevizieZile.toString());
    _oraNotificare = s.oraNotificare;
    _initializat = true;
  }

  Future<void> _salveaza(DateProvider date) async {
    await date.salveazaSetari(
      SetariAlerte(
        alertaITP: int.tryParse(_itpCtrl.text) ?? 30,
        alertaRovinieta: int.tryParse(_rovCtrl.text) ?? 15,
        alertaAsigurare: int.tryParse(_asigCtrl.text) ?? 15,
        alertaRevizieZile: int.tryParse(_revCtrl.text) ?? 30,
        oraNotificare: _oraNotificare,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Setări salvate.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final date = context.watch<DateProvider>();
    _initializeaza(date.setari);

    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (auth.eroareInregistrareNotificari != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Notificările push nu au putut fi activate: ${auth.eroareInregistrareNotificari}',
                  ),
                ),
              ),
            Text(
              'Praguri alertă (zile înainte de expirare)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itpCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(
                labelText: 'ITP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rovCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(
                labelText: 'Rovinietă',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _asigCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(
                labelText: 'Asigurări',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _revCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(
                labelText: 'Revizii',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Oră notificare zilnică:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _oraNotificare,
                  items: List.generate(24, (h) => h)
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text('${h.toString().padLeft(2, '0')}:00'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _oraNotificare = v ?? 8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _salveaza(date),
              child: const Text('Salvează setările'),
            ),
            const Divider(height: 40),
            Text(
              'Rovinietă / TollRo (CNAIR)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Din 1 octombrie 2026, CNAIR a înlocuit erovinieta.ro cu sistemul '
              'TollRo (portalul etoll.ro). Sincronizarea automată nu e disponibilă '
              '(protecție anti-automatizare) — folosește linkul de mai jos pentru '
              'verificare manuală.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://www.etoll.ro'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Deschide contul etoll.ro'),
            ),
            const Divider(height: 40),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().delogare(),
              icon: const Icon(Icons.logout),
              label: const Text('Delogare'),
            ),
          ],
        ),
      ),
    );
  }
}

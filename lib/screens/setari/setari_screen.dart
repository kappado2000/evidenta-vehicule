import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/date_provider.dart';
import '../../services/garaj_service.dart';
import '../garaj/garaj_screen.dart';

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
  final _garajService = GarajService();
  bool _seTrimiteTest = false;

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
        alertaITP: int.tryParse(_itpCtrl.text) ?? 10,
        alertaRovinieta: int.tryParse(_rovCtrl.text) ?? 3,
        alertaAsigurare: int.tryParse(_asigCtrl.text) ?? 3,
        alertaRevizieZile: int.tryParse(_revCtrl.text) ?? 7,
        oraNotificare: _oraNotificare,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Setări salvate.')));
    }
  }

  Future<void> _trimiteNotificareTest() async {
    setState(() => _seTrimiteTest = true);
    try {
      final r = await _garajService.trimiteNotificareTest();
      if (!mounted) return;
      if (r.trimise > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trimisă cu succes către ${r.trimise}/${r.total} dispozitive.',
            ),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Niciun dispozitiv n-a primit-o'),
            content: SingleChildScrollView(
              child: Text(
                r.erori.isEmpty
                    ? '${r.esuate}/${r.total} eșuate, fără detalii.'
                    : r.erori.join('\n'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare: $e')));
    } finally {
      if (mounted) setState(() => _seTrimiteTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final date = context.watch<DateProvider>();
    final culori = Theme.of(context).colorScheme;
    final culoarePrimara = culori.primary;
    final culoareOnPrimara = culori.onPrimary;
    _initializeaza(date.setari);

    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          // Padding jos generos - bara de navigare e plutitoare (peste
          // conținut, Scaffold.extendBody).
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          children: [
            if (auth.eroareInregistrareNotificari != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificările push nu au putut fi activate: ${auth.eroareInregistrareNotificari}',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              auth.reincearcaInregistrareNotificari(),
                          child: const Text('Reîncearcă'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Același efect "capsulă" (gradient + contur închis + umbră) ca
            // la antetele ITP/Rovinietă/Asigurări/Revizii din iconița MedRO -
            // un FilledButton obișnuit nu poate avea gradient, de-aia e
            // construit manual peste InkWell. Align ca să nu se întindă pe
            // toată lățimea (Container într-un ListView altfel se întinde).
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8A5A04),
                    width: 1.5,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE26E),
                      Color(0xFFF7B518),
                      Color(0xFFCD8006),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _seTrimiteTest ? null : _trimiteNotificareTest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _seTrimiteTest
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Colors.black87,
                                ),
                          const SizedBox(width: 8),
                          const Text(
                            'Trimite notificare de test',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 40),
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
            Align(
              alignment: Alignment.centerLeft,
              // Același efect "capsulă" (gradient + contur închis + umbră) ca
              // la celelalte butoane, dar pe culoarea temei (teal), nu galben.
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color.alphaBlend(
                      Colors.black.withValues(alpha: 0.35),
                      culoarePrimara,
                    ),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.45),
                        culoarePrimara,
                      ),
                      culoarePrimara,
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.25),
                        culoarePrimara,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://www.etoll.ro'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, color: culoareOnPrimara),
                          const SizedBox(width: 8),
                          Text(
                            'Deschide contul etoll.ro',
                            style: TextStyle(
                              color: culoareOnPrimara,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 40),
            Card(
              child: ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Garaj'),
                subtitle: const Text('Membri și invitații'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const GarajScreen())),
              ),
            ),
            const Divider(height: 40),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
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

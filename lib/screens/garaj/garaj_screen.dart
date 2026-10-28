import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/garaj_service.dart';

class GarajScreen extends StatefulWidget {
  const GarajScreen({super.key});

  @override
  State<GarajScreen> createState() => _GarajScreenState();
}

class _GarajScreenState extends State<GarajScreen> {
  final _garajService = GarajService();
  final _emailCtrl = TextEditingController();
  bool _seInvita = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _invita() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    setState(() => _seInvita = true);
    try {
      final trimis = await _garajService.invitaMembru(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trimis
              ? 'Invitație trimisă către $email.'
              : 'Invitație creată, dar emailul nu s-a putut trimite.'),
        ));
        _emailCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Eroare: $e')));
      }
    } finally {
      if (mounted) setState(() => _seInvita = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final garajId = auth.garajId;

    return Scaffold(
      appBar: AppBar(title: const Text('Garaj')),
      body: garajId == null
          ? const SizedBox.shrink()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('garaje')
                  .doc(garajId)
                  .snapshots(),
              builder: (context, snap) {
                final membriInfo = Map<String, dynamic>.from(
                    snap.data?.data()?['membriInfo'] as Map? ?? {});
                final owner = snap.data?.data()?['owner'] as String?;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Membri garaj',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (membriInfo.isEmpty)
                      const Text('Se încarcă...')
                    else
                      ...membriInfo.entries.map((e) {
                        final uid = e.key;
                        final info = Map<String, dynamic>.from(e.value as Map);
                        final esteOwner = uid == owner;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(info['email'] as String? ?? uid),
                            subtitle: Text(esteOwner ? 'Proprietar' : 'Membru'),
                            trailing: (auth.esteProprietar && !esteOwner)
                                ? IconButton(
                                    icon: const Icon(Icons.person_remove_outlined),
                                    onPressed: () async {
                                      await _garajService.eliminaMembru(uid);
                                    },
                                  )
                                : null,
                          ),
                        );
                      }),
                    if (auth.esteProprietar) ...[
                      const SizedBox(height: 24),
                      Text('Invită un membru nou',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _seInvita ? null : _invita,
                          child: _seInvita
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Invită'),
                        ),
                      ]),
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                            'Doar proprietarul garajului poate invita sau elimina membri.'),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
